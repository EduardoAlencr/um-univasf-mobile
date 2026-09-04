"""Gera o ícone do launcher (mipmap-*/ic_launcher.png) com a identidade
visual do app: gradiente azul + "UM" + ponto amarelo, igual ao logo usado
na tela de login. Roda uma vez, não faz parte do pipeline do scraper.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

AZUL_INICIO = (0, 180, 240)
AZUL_FIM = (0, 119, 200)
AMARELO = (255, 203, 5)
BRANCO = (255, 255, 255)

TAMANHOS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

RES_DIR = Path(__file__).parent.parent / "android" / "app" / "src" / "main" / "res"


def _gradiente_diagonal(tamanho: int) -> Image.Image:
    base = Image.new("RGB", (tamanho, tamanho))
    px = base.load()
    for y in range(tamanho):
        for x in range(tamanho):
            t = (x + y) / (2 * tamanho)
            r = int(AZUL_INICIO[0] + (AZUL_FIM[0] - AZUL_INICIO[0]) * t)
            g = int(AZUL_INICIO[1] + (AZUL_FIM[1] - AZUL_INICIO[1]) * t)
            b = int(AZUL_INICIO[2] + (AZUL_FIM[2] - AZUL_INICIO[2]) * t)
            px[x, y] = (r, g, b)
    return base


def _fonte(tamanho_px: int) -> ImageFont.FreeTypeFont:
    candidatos = [
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
    ]
    for caminho in candidatos:
        if Path(caminho).exists():
            return ImageFont.truetype(caminho, tamanho_px)
    return ImageFont.load_default()


def gerar(tamanho: int) -> Image.Image:
    img = _gradiente_diagonal(tamanho).convert("RGBA")
    draw = ImageDraw.Draw(img)

    fonte = _fonte(int(tamanho * 0.52))
    texto = "UM"
    bbox = draw.textbbox((0, 0), texto, font=fonte)
    largura_texto = bbox[2] - bbox[0]
    altura_texto = bbox[3] - bbox[1]
    pos_x = (tamanho - largura_texto) / 2 - bbox[0]
    pos_y = (tamanho - altura_texto) / 2 - bbox[1]
    draw.text((pos_x, pos_y), texto, font=fonte, fill=BRANCO)

    # ponto amarelo, igual ao acento da marca no app
    raio = tamanho * 0.07
    cx = tamanho * 0.685
    cy = tamanho * 0.235
    draw.ellipse([cx - raio, cy - raio, cx + raio, cy + raio], fill=AMARELO)

    return img


def main() -> None:
    for pasta, tamanho in TAMANHOS.items():
        destino = RES_DIR / pasta / "ic_launcher.png"
        destino.parent.mkdir(parents=True, exist_ok=True)
        gerar(tamanho).save(destino)
        print(f"{destino} ({tamanho}x{tamanho})")


if __name__ == "__main__":
    main()
