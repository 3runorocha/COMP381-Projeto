# -*- coding: utf-8 -*-
"""Blockout do mestre do Guerreiro alagoano.

Blockout e so proporcao e silhueta: sem detalhe, sem topologia boa, sem UV.
O objetivo e travar as medidas e a leitura da silhueta a distancia de camera
antes de gastar tempo com acabamento.

A peca que define o personagem e o CHAPEU EM FORMA DE CATEDRAL. Segundo o
Forum de Cultura Popular alagoano, os chapeus do Guerreiro tem formato de
igrejas, palacios e catedrais, e os do mestre e do contramestre representam
justamente as catedrais. Ver docs/guerreiro-referencia.md.

Rodar:
    blender --background --python tools/blockout_mestre.py

Gera assets/mestre_blockout.blend e assets/mestre_blockout.glb.

Blender e Z para cima; o exportador glTF converte para Y para cima, que e o
que o Godot espera.
"""

import bpy
import math
import os

# --- medidas, em metros -------------------------------------------------------
# O corpo tem 1.8, mesma altura da capsula placeholder do jogador. O chapeu
# acrescenta quase um metro de proposito: as fontes descrevem os chapeus como
# gigantes, e e ele que faz o personagem ser reconhecivel de longe.

ALTURA_CORPO = 1.80
TOPO_CABECA = 1.90
BASE_CHAPEU = TOPO_CABECA

CORES = {
    "pele": (0.76, 0.57, 0.44, 1.0),
    "roupa": (0.78, 0.16, 0.18, 1.0),
    "meia": (0.94, 0.94, 0.92, 1.0),
    "chapeu": (0.16, 0.34, 0.68, 1.0),
    "dourado": (0.90, 0.72, 0.22, 1.0),
    "manto": (0.20, 0.52, 0.34, 1.0),
}

_materiais = {}


def material(nome):
    if nome in _materiais:
        return _materiais[nome]
    mat = bpy.data.materials.new(name=nome)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = CORES[nome]
    # O Workbench, usado na previa, le diffuse_color e ignora o BSDF.
    mat.diffuse_color = CORES[nome]
    _materiais[nome] = mat
    return mat


def caixa(nome, centro, tamanho, cor):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=centro)
    obj = bpy.context.active_object
    obj.name = nome
    obj.scale = tamanho
    obj.data.materials.append(material(cor))
    return obj


def cilindro(nome, centro, raio, altura, cor):
    bpy.ops.mesh.primitive_cylinder_add(radius=raio, depth=altura, location=centro, vertices=16)
    obj = bpy.context.active_object
    obj.name = nome
    obj.data.materials.append(material(cor))
    return obj


def cone(nome, centro, raio, altura, cor):
    bpy.ops.mesh.primitive_cone_add(radius1=raio, radius2=0.0, depth=altura, location=centro, vertices=12)
    obj = bpy.context.active_object
    obj.name = nome
    obj.data.materials.append(material(cor))
    return obj


def limpar_cena():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bloco in (bpy.data.meshes, bpy.data.materials):
        for item in list(bloco):
            bloco.remove(item)


def construir_corpo():
    """Calcoes curtos e meias brancas longas, como as fontes descrevem."""
    # Pernas mais grossas e mais juntas que na primeira versao: finas e
    # afastadas liam como palito, e o personagem parecia quebra-nozes.
    for lado, x in (("esq", -0.115), ("dir", 0.115)):
        cilindro("meia_" + lado, (x, 0.0, 0.36), 0.10, 0.72, "meia")
        caixa("sapato_" + lado, (x, -0.05, 0.035), (0.18, 0.28, 0.07), "dourado")

    caixa("calcao", (0.0, 0.0, 0.85), (0.44, 0.32, 0.30), "roupa")
    caixa("torso", (0.0, 0.0, 1.24), (0.46, 0.30, 0.48), "roupa")

    # Ombro explicito: sem ele os bracos pareciam tubos soltos ao lado.
    caixa("ombros", (0.0, 0.0, 1.44), (0.64, 0.30, 0.13), "roupa")

    # Guarda-peito: peca citada nas fontes, fica sobre o peito.
    caixa("guarda_peito", (0.0, -0.17, 1.26), (0.44, 0.07, 0.34), "dourado")

    for lado, x in (("esq", -0.29), ("dir", 0.29)):
        cilindro("braco_" + lado, (x, 0.0, 1.20), 0.085, 0.44, "roupa")

    caixa("pescoco", (0.0, 0.0, 1.53), (0.17, 0.17, 0.09), "pele")
    # Cabeca maior: personagem de jogo le melhor com cabeca grande, e antes ela
    # sumia entre o torso e a aba do chapeu.
    caixa("cabeca", (0.0, 0.0, 1.73), (0.31, 0.29, 0.31), "pele")

    # Manto nas costas. E ele que o jogador ve a maior parte do tempo, porque a
    # camera do jogo fica atras.
    caixa("manto", (0.0, 0.20, 1.16), (0.60, 0.06, 0.80), "manto")


def construir_chapeu_catedral():
    """Chapeu em forma de catedral: a marca do mestre.

    Fachada com rosacea na frente, abside arredondada atras, duas torres com
    pinaculos. A abside existe porque no jogo a camera fica ATRAS do jogador:
    sem ela, a silhueta que o jogador mais ve seria uma caixa lisa.
    """
    base = BASE_CHAPEU

    caixa("chapeu_aba", (0.0, 0.0, base + 0.05), (0.50, 0.44, 0.10), "dourado")
    caixa("chapeu_nave", (0.0, 0.02, base + 0.36), (0.32, 0.30, 0.52), "chapeu")

    # Fachada, virada para a frente.
    caixa("chapeu_fachada", (0.0, -0.14, base + 0.42), (0.36, 0.06, 0.64), "chapeu")
    rosacea = cilindro("chapeu_rosacea", (0.0, -0.18, base + 0.48), 0.08, 0.03, "dourado")
    rosacea.rotation_euler = (math.radians(90.0), 0.0, 0.0)

    # Abside: a traseira arredondada, que e a vista de jogo.
    abside = cilindro("chapeu_abside", (0.0, 0.17, base + 0.34), 0.16, 0.46, "chapeu")
    caixa("contraforte_esq", (-0.13, 0.20, base + 0.26), (0.06, 0.20, 0.34), "dourado")
    caixa("contraforte_dir", (0.13, 0.20, base + 0.26), (0.06, 0.20, 0.34), "dourado")

    for lado, x in (("esq", -0.17), ("dir", 0.17)):
        caixa("torre_" + lado, (x, -0.06, base + 0.46), (0.13, 0.15, 0.76), "chapeu")
        cone("pinaculo_" + lado, (x, -0.06, base + 0.96), 0.09, 0.26, "dourado")

    caixa("cruz_haste", (0.0, 0.02, base + 0.74), (0.04, 0.04, 0.26), "dourado")
    caixa("cruz_braco", (0.0, 0.02, base + 0.81), (0.17, 0.04, 0.04), "dourado")


def juntar_e_exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    corpo = bpy.data.objects.get("torso")
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.join()

    mestre = bpy.context.active_object
    mestre.name = "MestreBlockout"

    # Origem nos pes, em z = 0: e o que faz o modelo assentar no chao do Godot
    # sem ninguem ter que adivinhar deslocamento.
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "assets")
    os.makedirs(destino, exist_ok=True)

    caminho_glb = os.path.join(destino, "mestre_blockout.glb")
    bpy.ops.export_scene.gltf(filepath=caminho_glb, export_format="GLB")

    caminho_blend = os.path.join(destino, "mestre_blockout.blend")
    bpy.ops.wm.save_as_mainfile(filepath=caminho_blend)

    dim = mestre.dimensions
    print("BLOCKOUT largura %.2f  profundidade %.2f  altura %.2f" % (dim.x, dim.y, dim.z))
    print("BLOCKOUT vertices %d  faces %d" % (len(mestre.data.vertices), len(mestre.data.polygons)))
    print("BLOCKOUT glb   %s" % caminho_glb)
    print("BLOCKOUT blend %s" % caminho_blend)


limpar_cena()
construir_corpo()
construir_chapeu_catedral()
juntar_e_exportar()
