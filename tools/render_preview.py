# -*- coding: utf-8 -*-
"""Renderiza uma previa do blockout, para julgar silhueta sem abrir o Blender.

Usa o motor Workbench de proposito: e chapado e rapido, que e exatamente o que
serve para avaliar volume e silhueta. Sombra bonita atrapalharia a leitura.

Rodar:
    blender --background --python tools/render_preview.py
"""

import bpy
import math
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLEND = os.path.join(RAIZ, "assets", "mestre_blockout.blend")
SAIDA = os.path.join(RAIZ, "assets", "mestre_blockout_previa.png")

bpy.ops.wm.open_mainfile(filepath=BLEND)

alvo = bpy.data.objects.new("Alvo", None)
bpy.context.scene.collection.objects.link(alvo)
alvo.location = (0.0, 0.0, 1.45)

bpy.ops.object.camera_add(location=(0.0, 0.0, 0.0))
camera = bpy.context.active_object
seguir = camera.constraints.new(type="TRACK_TO")
seguir.target = alvo
seguir.track_axis = "TRACK_NEGATIVE_Z"
seguir.up_axis = "UP_Y"
camera.data.lens = 45.0

cena = bpy.context.scene
cena.camera = camera
cena.render.engine = "BLENDER_WORKBENCH"
cena.render.resolution_x = 700
cena.render.resolution_y = 1000
cena.render.film_transparent = False

sombreado = cena.display.shading
sombreado.light = "STUDIO"
sombreado.color_type = "MATERIAL"
sombreado.show_shadows = True
sombreado.show_cavity = True

cena.world.color = (0.86, 0.87, 0.90)

# Duas vistas. A de costas importa mais que a de frente: e a que o jogador ve,
# porque a camera do jogo fica atras do personagem.
VISTAS = (
    ("frente", (3.0, -4.6, 2.6)),
    ("costas", (2.2, 4.8, 2.8)),
)

for nome, posicao in VISTAS:
    camera.location = posicao
    saida = os.path.join(RAIZ, "assets", "mestre_blockout_%s.png" % nome)
    cena.render.filepath = saida
    bpy.ops.render.render(write_still=True)
    print("PREVIA %s" % saida)
