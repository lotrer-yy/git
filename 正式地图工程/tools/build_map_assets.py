"""将作者整图及分层背景无损切片，生成可编辑场景与原坐标清单。"""
from pathlib import Path
import argparse
import hashlib
import json
import math

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = 150_000_000
ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT, TILE = 1920, 52000, 2048


def rgba(path):
    image = Image.open(path).convert("RGBA")
    if image.size != (WIDTH, HEIGHT):
        raise ValueError(f"画布尺寸应为 {WIDTH}×{HEIGHT}: {path}")
    return image


def expand_mask(mask, radius):
    """矩形邻域扩张，横纵分离，避免超长画布使用大核排序滤镜。"""
    horizontal = mask.copy()
    for step in range(1, radius + 1):
        horizontal[:, step:] |= mask[:, :-step]
        horizontal[:, :-step] |= mask[:, step:]
    result = horizontal.copy()
    for step in range(1, radius + 1):
        result[step:] |= horizontal[:-step]
        result[:-step] |= horizontal[step:]
    return result


def main(source):
    source = Path(source)
    full_path = source / "游戏总地图.png"
    original = rgba(full_path)
    foreground_path = source / "游戏总地图-前景.png"
    foreground = rgba(foreground_path)
    # 底图只由背景组成，不再使用带墙壁和前景的合成总图兜底。
    # 这样移动背景时不会露出第二套固定轮廓或黑边。
    backdrop = Image.new("RGBA", (WIDTH, HEIGHT), (255, 255, 255, 255))
    manifest = {"canvas": [WIDTH, HEIGHT], "sources": {}, "layers": {}}
    layers = []
    for key, title, expected, opaque in [
        ("Sky", "天空", (4800, 19100), True),
        ("Jungle", "丛林", (17400, 29800), True),
        ("Ocean", "海底", (29800, 39400), False),
        ("Hell", "地狱", (41200, 52000), False),
    ]:
        path = source / f"游戏总地图-{title}背景.png"
        manifest["sources"][path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        # 白底与参考线只在导入副本里去除，作者原图不改动。
        y0, y1 = expected
        art = np.array(rgba(path).crop((0, y0, WIDTH, y1)))
        if opaque:
            white = np.min(art[:, :, :3], axis=2) >= 248
            guide = ((art[:, :, 0] < 90) & (art[:, :, 1] > 65)
                     & (art[:, :, 1] < 200) & (art[:, :, 2] > 215))
            art[:, :, 3][white | guide] = 0
        active_rows = np.flatnonzero(np.count_nonzero(art[:, :, 3] > 100, axis=1) > 50)
        if not len(active_rows):
            raise ValueError(f"背景没有有效内容: {path}")
        first, last = int(active_rows[0]), int(active_rows[-1]) + 1
        art = art[first:last]
        top = y0 + first
        bottom = top + art.shape[0]
        if key == "Hell":
            # 这张背景导出仍含旧侧墙。只在被前景覆盖的外侧做纹理边缘延展，
            # 避免旧描边跟随视差移动并从新版固定侧墙内侧露出来。
            margin = 280
            art[:, :margin] = art[:, margin:margin + 1]
            art[:, -margin:] = art[:, -margin - 1:-margin]
        background = Image.fromarray(art)
        backdrop.alpha_composite(background, (0, top))
        layers.append((key, background, top))
        manifest["layers"][key] = {"top": top, "bottom": bottom, "title": title}
    # 作者前景是白底导出，白云也是白色，不能按颜色一刀切。
    # 用作者总图 C、白底前景 Fw、独立背景 B 恢复白底遮罩：
    # C-Fw = (1-alpha)*(B-white)。仅恢复透明度，不推算或重画轮廓。
    # 对抗锯齿边缘反白底，避免黑边外面留下白色毛边。
    for top in range(0, HEIGHT, 512):
        bottom = min(top + 512, HEIGHT)
        padded_top, padded_bottom = max(0, top - 8), min(HEIGHT, bottom + 8)
        box = (0, padded_top, WIDTH, padded_bottom)
        f = np.array(foreground.crop(box)).astype(np.float32)
        c = np.array(original.crop(box))[:, :, :3].astype(np.float32)
        b = np.array(backdrop.crop(box))[:, :, :3].astype(np.float32)
        direction = b - 255.0
        denominator = np.sum(direction * direction, axis=2)
        uncovered = np.divide(np.sum((c - f[:, :, :3]) * direction, axis=2),
                              denominator, out=np.zeros_like(denominator),
                              where=denominator > 1.0)
        inferred_alpha = 1.0 - np.clip(uncovered, 0, 1)
        white = np.min(f[:, :, :3], axis=2) >= 248
        white_hole = white & (np.max(np.abs(c - f[:, :, :3]), axis=2) > 8)
        # 新前景里的实色绘画是权威内容，即使和旧合成图的岸边等细节有差别也不改色。
        # 总图只用于区分白底和白云，并在白底边缘恢复抗锯齿透明度。
        # 只有符合白底合成公式的边缘才恢复透明度，不能把新版岸边的实色变成半透明。
        border = expand_mask(white_hole, 8)
        residual = np.max(np.abs((c - f[:, :, :3]) - uncovered[:, :, None] * direction), axis=2)
        alpha = np.where(border & (residual <= 4.0), inferred_alpha, 1.0)
        alpha[white_hole] = 0
        alpha[alpha < 0.02] = 0
        alpha[alpha > 0.98] = 1
        # 去掉导出时带进来的蓝色水平参考线；总图中的实际绘画不受影响。
        guide = ((f[:, :, 0] < 90) & (f[:, :, 1] > 65)
                 & (f[:, :, 1] < 200) & (f[:, :, 2] > 215))
        line_rows = np.count_nonzero(guide, axis=1) > WIDTH * 0.5
        guide &= line_rows[:, None]
        alpha[guide] = 0
        rgb = np.divide(f[:, :, :3] - (1 - alpha[:, :, None]) * 255.0,
                        alpha[:, :, None], out=np.zeros_like(f[:, :, :3]),
                        where=alpha[:, :, None] > 0)
        clean = np.concatenate([np.clip(rgb, 0, 255), alpha[:, :, None] * 255], axis=2)
        clean = clean[top - padded_top:bottom - padded_top]
        foreground.paste(Image.fromarray(np.rint(clean).astype(np.uint8)), (0, top))
    layers.insert(0, ("Base", backdrop, 0))
    layers.append(("Foreground", foreground, 0))
    scene = ['[gd_scene format=3]',
             '[ext_resource type="Script" path="res://modules/map/finite_parallax.gd" id="parallax"]']
    nodes = []
    resources = 0
    for key, image, origin in layers:
        node_path = key if key in ("Base", "Foreground") else f"Backgrounds/{key}"
        if key == "Base":
            nodes += ['[node name="WorldMap" type="Node2D"]',
                      '[node name="Base" type="Node2D" parent="."]', 'z_index=-30',
                      '[node name="Backgrounds" type="Node2D" parent="."]', 'z_index=-20']
        elif key == "Foreground":
            nodes += ['[node name="Foreground" type="Node2D" parent="."]', 'z_index=10']
        else:
            top, bottom = manifest["layers"][key]["top"], manifest["layers"][key]["bottom"]
            nodes += [f'[node name="{key}" type="Node2D" parent="Backgrounds"]',
                      'script=ExtResource("parallax")',
                      'camera_path=NodePath("../../../Camera")',
                      f'region_top={top}.0', f'region_bottom={bottom}.0']
        directory = ROOT / "assets" / "map" / key.lower()
        directory.mkdir(parents=True, exist_ok=True)
        chunks = []
        for index, y in enumerate(range(0, image.height, TILE)):
            height = min(TILE, image.height - y)
            crop = image.crop((0, y, WIDTH, y + height))
            # 一像素边缘延展用于纹理过滤；显示区域仍严格等于原图范围。
            padded = Image.new("RGBA", (WIDTH, height + 2))
            padded.paste(crop, (0, 1))
            padded.paste(crop.crop((0, 0, WIDTH, 1)), (0, 0))
            padded.paste(crop.crop((0, height - 1, WIDTH, height)), (0, height + 1))
            name = f"{index:02d}"
            full = directory / f"{name}.png"
            preview = directory / f"{name}_preview.png"
            padded.save(full)
            ph = math.ceil(height / 10)
            crop.resize((192, ph), Image.Resampling.LANCZOS).save(preview)
            resources += 1
            rid = f"tile{resources}"
            rel = preview.relative_to(ROOT).as_posix()
            full_rel = full.relative_to(ROOT).as_posix()
            scene.append(f'[ext_resource type="Texture2D" path="res://{rel}" id="{rid}"]')
            nodes += [f'[node name="Chunk{name}" type="Sprite2D" parent="{node_path}"]',
                      f'position=Vector2(0,{origin+y})',
                      f'scale=Vector2(10,{height/ph:.10f})',
                      f'texture=ExtResource("{rid}")', 'centered=false',
                      f'metadata/full_texture="res://{full_rel}"',
                      f'metadata/pixel_height={height}']
            chunks.append({"path": full_rel, "top": origin+y, "height": height})
        manifest.setdefault("chunks", {})[key] = chunks
    (ROOT / "scenes" / "map").mkdir(parents=True, exist_ok=True)
    (ROOT / "scenes" / "map" / "world_map.tscn").write_text("\n".join(scene + nodes) + "\n", encoding="utf-8")
    manifest["sources"][full_path.name] = hashlib.sha256(full_path.read_bytes()).hexdigest()
    manifest["sources"][foreground_path.name] = hashlib.sha256(foreground_path.read_bytes()).hexdigest()
    manifest["foreground_method"] = "作者独立前景；仅恢复白底透明度、去除导出参考线；不再从总图推算轮廓"
    manifest["background_wall_cleanup"] = "地狱背景两侧各 280 像素延展相邻背景纹理，去除导出中自带的旧侧墙；显示侧墙仅来自新版前景"
    (ROOT / "assets" / "map" / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"地图切片完成：{resources} 块，原坐标与蓝色参考线检查已记录。", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source_directory", type=Path)
    main(parser.parse_args().source_directory)
