"""Builds Google Play graphics from raw emulator screenshots.

usage: python compose.py <raw_shots_dir> <out_dir>
needs: Pillow (and `qrcode` to paint the sample QR into the scanner shot)
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAW, OUT = sys.argv[1], sys.argv[2]
FONT = '/System/Library/Fonts/Avenir Next.ttc'
BOLD, MED = 0, 5
ORANGE = (255, 159, 10)
W, H = 1080, 1920


def font(size, idx=BOLD):
    return ImageFont.truetype(FONT, size, index=idx)


def gradient_bg(w, h):
    """Near-black background with a warm orange glow at the top."""
    bg = Image.new('RGB', (w, h), (11, 12, 15))
    glow = Image.new('RGB', (w, h), (0, 0, 0))
    ImageDraw.Draw(glow).ellipse([-w * 0.3, -h * 0.25, w * 1.3, h * 0.38], fill=(78, 40, 0))
    return _add(bg, glow.filter(ImageFilter.GaussianBlur(w * 0.12)))


def _add(a, b):
    from PIL import ImageChops
    return ImageChops.add(a, b)


def rounded(img, r):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], r, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def phone(shot, width):
    h = int(width * shot.height / shot.width)
    s = shot.resize((width, h), Image.LANCZOS)
    r = int(width * 0.085)
    b = 12
    framed = Image.new('RGBA', (width + 2 * b, h + 2 * b), (0, 0, 0, 0))
    ImageDraw.Draw(framed).rounded_rectangle(
        [0, 0, framed.width - 1, framed.height - 1], r + b, fill=(46, 46, 50, 255))
    ImageDraw.Draw(framed).rounded_rectangle(
        [3, 3, framed.width - 4, framed.height - 4], r + b - 3, outline=(90, 90, 96, 255), width=2)
    framed.alpha_composite(rounded(s, r), (b, b))
    return framed


def shadow_paste(canvas, ph, xy):
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    blob = Image.new('RGBA', ph.size, (0, 0, 0, 200))
    blob.putalpha(ph.split()[3].point(lambda v: 200 if v else 0))
    sh.paste(blob, (xy[0], xy[1] + 30), blob)
    sh = sh.filter(ImageFilter.GaussianBlur(40))
    canvas.alpha_composite(sh)
    canvas.alpha_composite(ph, xy)


def caption(canvas, title, sub, accent):
    d = ImageDraw.Draw(canvas)
    f1, f2 = font(84), font(40, MED)
    lines = title.split('\n')
    y = 120
    for ln in lines:
        w = d.textlength(ln, font=f1)
        # accent word in orange
        parts = ln.split(accent) if accent and accent in ln else [ln]
        if len(parts) == 2:
            a, b = parts
            wa, wb, wc = d.textlength(a, font=f1), d.textlength(accent, font=f1), d.textlength(b, font=f1)
            x = (W - (wa + wb + wc)) / 2
            d.text((x, y), a, font=f1, fill=(255, 255, 255))
            d.text((x + wa, y), accent, font=f1, fill=ORANGE)
            d.text((x + wa + wb, y), b, font=f1, fill=(255, 255, 255))
        else:
            d.text(((W - w) / 2, y), ln, font=f1, fill=(255, 255, 255))
        y += 104
    sw = d.textlength(sub, font=f2)
    d.text(((W - sw) / 2, y + 14), sub, font=f2, fill=(190, 190, 198))


def load(name):
    return Image.open(os.path.join(RAW, name + '.png')).convert('RGB')


def prep_qr(shot):
    """Paint a sample QR into the emulator's virtual-room camera view and
    hide the status bar chips of the immersive screen."""
    try:
        import qrcode
    except ImportError:
        return shot
    px = shot.load()
    for y in range(0, 100):  # copy a clean row over the status bar area
        for x in range(shot.width):
            px[x, y] = px[x, 110]
    qr = qrcode.QRCode(border=1, box_size=10, error_correction=qrcode.constants.ERROR_CORRECT_M)
    qr.add_data('uygon-demo')
    qr.make(fit=True)
    img = qr.make_image(fill_color='black', back_color='white').convert('RGB').resize((400, 400), Image.NEAREST)
    shot = shot.copy()
    shot.paste(rounded(img, 24), (340, 1210), rounded(img, 24))
    return shot


SLIDES = [
    ('home',       "Budilniklaringiz\nbir joyda",        "Sodda, toza va tushunarli",             "bir joyda"),
    ('edit',       "Vaqtni tez\nbelgilang",              "Ovoz, vazifa va takrorlash",            "tez"),
    ('challenges', "6 xil\nvazifa",                      "Matematikadan yurishgacha",             "6 xil"),
    ('ring_math',  "Vazifasiz\no'chmaydi",               "3 ta misolni ketma-ket yeching",        "o'chmaydi"),
    ('ring_shake_mid', "Telefonni\nsilkiting",           "20–50 marta silkitib budilnikni to'xtating", "silkiting"),
    ('ring_walk',  "Yurib\nuyg'oning",                   "50 metr yuring — budilnik o'chadi",     "uyg'oning"),
    ('ring_qr',    "QR yoki shtrix\nkodni skanerlang",   "Hammomdagi stikerni toping",            "skanerlang"),
    ('success',    "Xayrli\ntong!",                      "Har tongni g'alaba bilan boshlang",     "tong!"),
]

os.makedirs(os.path.join(OUT, 'phone'), exist_ok=True)
for i, (name, title, sub, accent) in enumerate(SLIDES, 1):
    shot = load(name)
    if name == 'ring_qr':
        shot = prep_qr(shot)
    canvas = gradient_bg(W, H).convert('RGBA')
    ph = phone(shot, 820)
    shadow_paste(canvas, ph, ((W - ph.width) // 2, 470))
    caption(canvas, title, sub, accent)
    canvas.convert('RGB').save(os.path.join(OUT, 'phone', f'{i:02d}_{name}.png'), optimize=True)

# Icon 512
icon = Image.open(os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'brand', 'icon.png')).convert('RGB')
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, 'icon-512.png'), optimize=True)

# Feature graphic 1024x500
FW, FH = 1024, 500
fg = Image.new('RGB', (FW, FH), (11, 12, 15))
glow = Image.new('RGB', (FW, FH), (0, 0, 0))
ImageDraw.Draw(glow).ellipse([-200, -250, 700, 450], fill=(80, 41, 0))
fg = _add(fg, glow.filter(ImageFilter.GaussianBlur(90))).convert('RGBA')
ic = rounded(icon.resize((170, 170), Image.LANCZOS), 40)
fg.alpha_composite(ic, (48, 165))
d = ImageDraw.Draw(fg)
d.text((246, 140), "Uyg'on", font=font(92), fill=(255, 255, 255))
d.text((250, 262), "Vazifani bajaring —", font=font(31, MED), fill=(235, 235, 240))
d.text((250, 304), "budilnik shundagina o'chadi", font=font(31, MED), fill=ORANGE)
for name, rot, x, y in [('ring_math', 6, 668, 55), ('home', -5, 846, 110)]:
    p = phone(load(name), 205)
    p = p.rotate(rot, expand=True, resample=Image.BICUBIC)
    shadow_paste(fg, p, (x, y))
fg.convert('RGB').save(os.path.join(OUT, 'feature-graphic-1024x500.png'), optimize=True)
print('ok')
