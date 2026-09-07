"""Painel administrativo local (desktop) para manter os dados do app
atualizados sem precisar mexer em código.

Hoje cobre o único arquivo que não tem URL pública estável e por isso exige
substituição manual: o PDF de itinerário dos ônibus da PROAE. O botão
"Rodar atualização agora" reaproveita o mesmo `run.py` usado pelo GitHub
Actions, e "Enviar para o GitHub" reaproveita o git já configurado nesta
máquina (nenhuma credencial é lida ou guardada por este script).

Uso: python admin_tool.py
"""
from __future__ import annotations

import subprocess
import sys
import threading
import tkinter as tk
from pathlib import Path
from shutil import copyfile
from tkinter import filedialog, scrolledtext

RAIZ_PROJETO = Path(__file__).parent.parent
CAMINHO_ITINERARIO = RAIZ_PROJETO / "MATERIAIS" / "Itinerário PROAE 2026.2.pdf"
CAMINHO_JSON_SAIDA = Path(__file__).parent / "output" / "dados_univasf.json"
CAMINHO_JSON_ASSET = RAIZ_PROJETO / "assets" / "data" / "dados_univasf.json"


class PainelAdmin(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("UM · UNIVASF Mobile — Painel Admin")
        self.geometry("640x480")
        self.resizable(True, True)
        self._montar_widgets()

    def _montar_widgets(self) -> None:
        tk.Label(
            self,
            text="Atualização de dados do app",
            font=("Segoe UI", 14, "bold"),
        ).pack(pady=(16, 4))
        tk.Label(
            self,
            text="Substitua o PDF de itinerário quando a PROAE publicar uma versão nova,\n"
            "rode a coleta de todos os dados e envie o resultado pro GitHub.",
            font=("Segoe UI", 9),
            justify="center",
        ).pack(pady=(0, 12))

        frame_botoes = tk.Frame(self)
        frame_botoes.pack(pady=4)

        tk.Button(
            frame_botoes,
            text="1. Selecionar novo PDF de itinerário",
            width=38,
            command=self._selecionar_pdf_itinerario,
        ).grid(row=0, column=0, padx=6, pady=6)

        tk.Button(
            frame_botoes,
            text="2. Rodar atualização agora",
            width=38,
            command=self._rodar_atualizacao,
        ).grid(row=1, column=0, padx=6, pady=6)

        tk.Button(
            frame_botoes,
            text="3. Enviar para o GitHub",
            width=38,
            command=self._enviar_github,
        ).grid(row=2, column=0, padx=6, pady=6)

        tk.Label(self, text="Log:", font=("Segoe UI", 9, "bold")).pack(anchor="w", padx=12)
        self.log_widget = scrolledtext.ScrolledText(self, height=16, font=("Consolas", 9))
        self.log_widget.pack(fill="both", expand=True, padx=12, pady=(0, 12))

    def _log(self, texto: str) -> None:
        self.log_widget.insert(tk.END, texto + "\n")
        self.log_widget.see(tk.END)
        self.update_idletasks()

    def _selecionar_pdf_itinerario(self) -> None:
        origem = filedialog.askopenfilename(
            title="Selecione o novo PDF de itinerário",
            filetypes=[("PDF", "*.pdf")],
        )
        if not origem:
            return
        try:
            CAMINHO_ITINERARIO.parent.mkdir(parents=True, exist_ok=True)
            copyfile(origem, CAMINHO_ITINERARIO)
            self._log(f"✔ PDF copiado para {CAMINHO_ITINERARIO}")
        except OSError as exc:
            self._log(f"✘ Falha ao copiar o PDF: {exc}")

    def _rodar_atualizacao(self) -> None:
        threading.Thread(target=self._rodar_atualizacao_thread, daemon=True).start()

    def _rodar_atualizacao_thread(self) -> None:
        self._log("\n--- Rodando scraper/run.py ---")
        try:
            processo = subprocess.run(
                [sys.executable, "run.py"],
                cwd=Path(__file__).parent,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        except OSError as exc:
            self._log(f"✘ Falha ao iniciar o scraper: {exc}")
            return

        if processo.stdout:
            self._log(processo.stdout.strip())
        if processo.returncode != 0:
            self._log(f"✘ O scraper terminou com erro (código {processo.returncode}).")
            if processo.stderr:
                self._log(processo.stderr.strip())
            return

        try:
            CAMINHO_JSON_ASSET.parent.mkdir(parents=True, exist_ok=True)
            copyfile(CAMINHO_JSON_SAIDA, CAMINHO_JSON_ASSET)
            self._log(f"✔ JSON copiado para {CAMINHO_JSON_ASSET}")
        except OSError as exc:
            self._log(f"✘ Falha ao copiar o JSON pros assets do app: {exc}")

    def _enviar_github(self) -> None:
        threading.Thread(target=self._enviar_github_thread, daemon=True).start()

    def _enviar_github_thread(self) -> None:
        self._log("\n--- Enviando para o GitHub ---")
        comandos = [
            ["git", "add", "assets/data/dados_univasf.json", "MATERIAIS"],
            ["git", "commit", "-m", "chore: atualizar dados via painel admin"],
            ["git", "push"],
        ]
        for cmd in comandos:
            try:
                processo = subprocess.run(
                    cmd,
                    cwd=RAIZ_PROJETO,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                )
            except OSError as exc:
                self._log(f"✘ Falha ao rodar {' '.join(cmd)}: {exc}")
                return
            self._log(f"$ {' '.join(cmd)}")
            if processo.stdout:
                self._log(processo.stdout.strip())
            if processo.stderr:
                self._log(processo.stderr.strip())
            if processo.returncode != 0 and "commit" in cmd:
                self._log("  (sem mudanças pra commitar — seguindo pro push só por garantia)")
            elif processo.returncode != 0:
                self._log(f"✘ Comando falhou (código {processo.returncode}), abortando.")
                return
        self._log("✔ Envio concluído.")


if __name__ == "__main__":
    PainelAdmin().mainloop()
