from pathlib import Path
import random
from PIL import Image, ImageDraw


REPO = Path(r"C:\Users\Esthe\OneDrive\Woonkamer Laptop Backup\AutoHotkey")
INTACT_PATH = REPO / "Lib" / "icon.png"
DESTROYED_PATH = Path(
    r"C:\Users\Esthe\.codex\generated_images\01a08cf7-7786-7972-b708-750b4bf309fe"
    r"\exec-3a271db2-bd71-450a-8fad-b35d989d88a1.png"
)
OUTPUT = REPO / "Dashboards" / "Macro Board" / "User Interface" / "assets" / "icons" / "control deck shutdown.gif"

SIZE = 420
BLACK = (9, 8, 7, 255)
RED = (201, 79, 79, 255)
DARK_RED = (90, 25, 29, 255)
AMBER = (217, 161, 59, 255)
IVORY = (216, 198, 165, 255)


def fit_square(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    scale = min(SIZE / image.width, SIZE / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.NEAREST,
    )
    canvas = Image.new("RGBA", (SIZE, SIZE), BLACK)
    canvas.alpha_composite(resized, ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2))
    return canvas


def shifted(image: Image.Image, dx: int, dy: int) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), BLACK)
    canvas.alpha_composite(image, (dx, dy))
    return canvas


intact = fit_square(Image.open(INTACT_PATH))
destroyed = fit_square(Image.open(DESTROYED_PATH))
frames: list[Image.Image] = []
durations: list[int] = []

# Calm intact state with a single red status lamp preparing to trip.
for step in range(7):
    frame = intact.copy()
    draw = ImageDraw.Draw(frame)
    lamp = RED if step in (2, 3, 4) else DARK_RED
    draw.rectangle((77, 54, 86, 59), fill=lamp)
    frames.append(frame)
    durations.append(105)

# Escalating warning border.
for step in range(5):
    frame = intact.copy()
    draw = ImageDraw.Draw(frame)
    inset = 7 + (step % 2) * 5
    draw.rectangle((inset, inset, SIZE - 1 - inset, SIZE - 1 - inset), outline=RED, width=3)
    draw.rectangle((18, SIZE - 18, 18 + (step + 1) * 68, SIZE - 14), fill=AMBER if step < 3 else RED)
    frames.append(frame)
    durations.append(80)

# Mechanical impact shake with a few large crack guides.
shake_offsets = [(-3, 0), (4, -2), (-5, 3), (4, 2), (-2, -1), (0, 0)]
for step, (dx, dy) in enumerate(shake_offsets):
    frame = shifted(intact, dx, dy)
    draw = ImageDraw.Draw(frame)
    crack = [(226 + dx, 160 + dy), (215 + dx, 192 + dy), (230 + dx, 220 + dy), (210 + dx, 254 + dy)]
    draw.line(crack[: step // 2 + 2], fill=BLACK, width=4)
    if step >= 3:
        draw.line([(276 + dx, 122 + dy), (289 + dx, 149 + dy), (278 + dx, 174 + dy)], fill=RED, width=3)
    frames.append(frame)
    durations.append(65)

# One hard failure flash.
flash = Image.new("RGBA", (SIZE, SIZE), DARK_RED)
flash_draw = ImageDraw.Draw(flash)
flash_draw.rectangle((12, 12, SIZE - 13, SIZE - 13), outline=IVORY, width=8)
flash_draw.line((55, 210, 365, 210), fill=RED, width=8)
flash_draw.line((210, 55, 210, 365), fill=RED, width=8)
frames.append(flash)
durations.append(55)

# Chunky failure dissolve from intact to destroyed.
rng = random.Random(4082)
tile = 14
tiles = [(x, y) for y in range(0, SIZE, tile) for x in range(0, SIZE, tile)]
tiles.sort(key=lambda p: (((p[0] - SIZE / 2) ** 2 + (p[1] - SIZE / 2) ** 2) ** 0.5) + rng.uniform(-85, 85))
for step in range(1, 14):
    frame = intact.copy()
    reveal_count = round(len(tiles) * step / 13)
    for x, y in tiles[:reveal_count]:
        patch = destroyed.crop((x, y, min(x + tile, SIZE), min(y + tile, SIZE)))
        frame.paste(patch, (x, y), patch)
    draw = ImageDraw.Draw(frame)
    spark_count = max(0, 8 - step // 2)
    for spark in range(spark_count):
        sx = 170 + ((spark * 37 + step * 19) % 120)
        sy = 120 + ((spark * 29 + step * 23) % 170)
        color = IVORY if spark % 3 == 0 else RED
        draw.rectangle((sx, sy, sx + 4, sy + 4), fill=color)
    frames.append(frame)
    durations.append(70)

# Broken casing settles with a short downward jolt.
settle_offsets = [(0, -3), (0, 2), (0, -1), (0, 1), (0, 0), (0, 0)]
for dx, dy in settle_offsets:
    frame = shifted(destroyed, dx, dy)
    frames.append(frame)
    durations.append(90)

# Power drains from top to bottom in hard scan bands.
for step in range(8):
    frame = destroyed.copy()
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cutoff = round(SIZE * (step + 1) / 9)
    draw.rectangle((0, 0, SIZE, cutoff), fill=(0, 0, 0, 40 + step * 8))
    draw.line((0, cutoff, SIZE, cutoff), fill=RED, width=2)
    frame = Image.alpha_composite(frame, overlay)
    frames.append(frame)
    durations.append(90)

# Final dead state, held long enough to read as shutdown.
dead = Image.alpha_composite(destroyed, Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 72)))
for step in range(8):
    frame = dead.copy()
    if step == 1:
        draw = ImageDraw.Draw(frame)
        draw.rectangle((77, 54, 83, 58), fill=DARK_RED)
    frames.append(frame)
    durations.append(150)

palette_seed = intact.convert("RGB").quantize(colors=128, method=Image.Quantize.MEDIANCUT)
gif_frames = [
    frame.convert("RGB").quantize(palette=palette_seed, dither=Image.Dither.NONE)
    for frame in frames
]

if OUTPUT.exists():
    raise FileExistsError(f"Refusing to overwrite existing output: {OUTPUT}")

gif_frames[0].save(
    OUTPUT,
    save_all=True,
    append_images=gif_frames[1:],
    duration=durations,
    loop=0,
    disposal=2,
    optimize=False,
)

print(f"created={OUTPUT}")
print(f"size={SIZE}x{SIZE}")
print(f"source_frames={len(gif_frames)}")
print(f"duration_ms={sum(durations)}")
