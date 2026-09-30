# -*- coding: utf-8 -*-
"""Guerreiro do cordao: versao simplificada do mestre, repetida 25 vezes.

Reaproveita as funcoes de blockout_mestre em vez de copia-las. O que muda e o
que foi cortado, e cada corte tem motivo:

  sem fitas        150 objetos a mais na cena, e a essa distancia de camera
                   elas nao se distinguem do corpo
  capacete menor   so aro, corpo e uma torre com telhado. Tres torres e cruz
                   viram uma mancha unica quando o boneco tem 60 pixels
  menor que o mestre  a hierarquia visual do folguedo: o mestre lidera o cordao

Rodar:
    blender --background --python tools/blockout_guerreiro.py
"""

import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import bpy
import blockout_mestre as base

ESCALA = 0.78  # menor que o mestre, de proposito


def construir():
    base.limpar_cena()

    for lado, x in (("esq", -0.10), ("dir", 0.10)):
        base.caixa("bota_" + lado, (x, -0.02, 0.07), (0.17, 0.24, 0.14), "vermelho")
        base.caixa("perna_" + lado, (x, 0.0, 0.36), (0.15, 0.19, 0.44), "azul")

    base.caixa("camisa", (0.0, 0.0, 0.78), (0.41, 0.24, 0.42), "vermelho")
    base.caixa("ombros", (0.0, 0.0, 0.94), (0.50, 0.24, 0.11), "vermelho")
    base.caixa("braco_esq", (-0.28, 0.0, 0.80), (0.11, 0.13, 0.34), "vermelho")
    base.caixa("braco_dir", (0.28, 0.0, 0.80), (0.11, 0.13, 0.34), "vermelho")
    base.caixa("cabeca", (0.0, 0.0, 1.24), (0.39, 0.35, 0.39), "pele")

    # Capacete reduzido: aro, corpo e uma torre. Mantem a silhueta de catedral
    # sem o custo de tres torres e uma cruz que somem no tamanho de tela real.
    topo = 1.43
    base.caixa("aro", (0.0, 0.0, topo + 0.05), (0.46, 0.40, 0.10), "branco")
    base.caixa("corpo_capacete", (0.0, 0.0, topo + 0.24), (0.40, 0.33, 0.28), "branco")
    base.caixa("torre", (0.0, 0.0, topo + 0.50), (0.17, 0.20, 0.24), "branco")
    base.cone("telhado", (0.0, 0.0, topo + 0.72), 0.125, 0.20, "vermelho")


def exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    corpo = bpy.data.objects.get("camisa")
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.join()


    # Gira tudo 180 graus em torno da origem do mundo, e APLICA.
    #
    # O exportador glTF manda o +Y do Blender para o -Z do Godot. Como o jogo
    # corre para -Z, o que foi construido como costas chegava virado para a
    # frente: o jogador via a cara do boneco e as fitas ficavam do outro lado.
    #
    # Aplicar a rotacao e essencial, nao cosmetico: as fitas sao animadas por
    # script, que ESCREVE em rotation. Se a volta de 180 ficasse guardada ali,
    # o primeiro quadro de animacao a apagaria.
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.transform.rotate(value=math.pi, orient_axis="Z",
                             center_override=(0.0, 0.0, 0.0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    guerreiro = bpy.context.active_object
    guerreiro.name = "Guerreiro"
    guerreiro.scale = (ESCALA, ESCALA, ESCALA)
    bpy.ops.object.transform_apply(scale=True)

    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "assets")
    caminho = os.path.join(destino, "guerreiro_blockout.glb")
    bpy.ops.export_scene.gltf(filepath=caminho, export_format="GLB")

    d = guerreiro.dimensions
    print("GUERREIRO largura %.2f altura %.2f" % (d.x, d.z))
    print("GUERREIRO vertices %d faces %d" % (
        len(guerreiro.data.vertices), len(guerreiro.data.polygons)))
    print("GUERREIRO glb %s" % caminho)


if __name__ == "__main__":
    construir()
    exportar()
