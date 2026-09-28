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

ALTURA_CORPO = 1.82
TOPO_CABECA = 1.82
BASE_CHAPEU = TOPO_CABECA

# Azul, branco e vermelho: as cores da bandeira de Alagoas. Roupa, capacete e
# fitas ficam restritos a elas. Pele fica de fora, nao e roupa.
CORES = {
    "pele": (0.62, 0.42, 0.29, 1.0),
    "vermelho": (0.80, 0.14, 0.16, 1.0),
    "azul": (0.13, 0.33, 0.66, 1.0),
    "branco": (0.95, 0.95, 0.93, 1.0),
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
    """Proporcao chibi, como na referencia: cabeca grande, pernas curtas.

    Roupa em uma cor so por peca, sem galao, botao nem cinto. Detalhe de
    indumentaria nao cabe num personagem que o jogador ve de longe e por tras.
    """
    # Duas pernas separadas de verdade. Antes eu punha uma caixa branca no meio
    # para "abrir" o vao, mas caixa soma geometria em vez de subtrair, e o
    # resultado era uma mancha branca pintada na calca.
    for lado, x in (("esq", -0.12), ("dir", 0.12)):
        caixa("bota_" + lado, (x, -0.03, 0.09), (0.21, 0.30, 0.18), "vermelho")
        caixa("perna_" + lado, (x, 0.0, 0.46), (0.19, 0.24, 0.56), "azul")

    caixa("camisa", (0.0, 0.0, 0.99), (0.52, 0.30, 0.54), "vermelho")
    caixa("ombros", (0.0, 0.0, 1.20), (0.64, 0.30, 0.14), "vermelho")

    # Braco esquerdo dobrado na cintura, direito solto: e a pose da referencia,
    # sem a espada, e ja quebra a simetria do boneco.
    caixa("braco_esq_alto", (-0.36, 0.0, 1.08), (0.14, 0.16, 0.30), "vermelho")
    caixa("braco_esq_baixo", (-0.27, 0.0, 0.90), (0.22, 0.16, 0.14), "vermelho")
    caixa("mao_esq", (-0.17, 0.0, 0.90), (0.11, 0.14, 0.14), "pele")

    caixa("braco_dir", (0.36, 0.0, 1.02), (0.14, 0.16, 0.44), "vermelho")
    caixa("mao_dir", (0.36, 0.0, 0.76), (0.13, 0.15, 0.13), "pele")

    caixa("pescoco", (0.0, 0.0, 1.29), (0.17, 0.17, 0.08), "pele")
    # Cabeca grande de proposito: e o que da a leitura chibi da referencia, e o
    # que sustenta um capacete deste tamanho sem parecer alfinete.
    caixa("cabeca", (0.0, 0.0, 1.57), (0.50, 0.44, 0.50), "pele")


def construir_capacete():
    """Capacete em forma de catedral, SO O FORMATO.

    Sem rosacea, sem bolinha, sem imagem de santo. A referencia tem tudo isso,
    mas detalhe some na distancia de camera do jogo e custa poligono a toa. O
    que identifica o mestre de longe sao as tres torres e a cruz.
    """
    base = BASE_CHAPEU

    caixa("aro", (0.0, 0.0, base + 0.06), (0.58, 0.50, 0.12), "branco")
    caixa("corpo_capacete", (0.0, 0.0, base + 0.27), (0.52, 0.42, 0.30), "branco")

    for lado, x in (("esq", -0.19), ("dir", 0.19)):
        caixa("torre_" + lado, (x, 0.0, base + 0.59), (0.15, 0.20, 0.34), "branco")
        cone("telhado_" + lado, (x, 0.0, base + 0.85), 0.115, 0.20, "vermelho")

    caixa("torre_centro", (0.0, 0.0, base + 0.65), (0.20, 0.24, 0.46), "branco")
    cone("telhado_centro", (0.0, 0.0, base + 0.99), 0.145, 0.22, "vermelho")
    caixa("cruz_haste", (0.0, 0.0, base + 1.19), (0.035, 0.035, 0.20), "vermelho")
    caixa("cruz_braco", (0.0, 0.0, base + 1.22), (0.14, 0.035, 0.035), "vermelho")


def construir_fitas():
    """Fitas caindo atras da cabeca, lendo como cabelo.

    Nao sao enfeite: a camera do jogo fica ATRAS do jogador, entao sao elas,
    junto com o capacete, que formam quase toda a silhueta que ele ve o tempo
    inteiro.

    Ficam agrupadas atras da cabeca, com folga visivel entre uma e outra, e nao
    abertas para os lados.

    Cada fita sai daqui como objeto SEPARADO, com o pivo no topo, onde ela
    encosta no capacete. E isso que permite balanca-las no jogo: numa malha
    unica nao haveria o que animar, e girar a partir do meio faria a ponta de
    cima furar o capacete.
    """
    topo = BASE_CHAPEU + 0.02
    cores = ("azul", "branco", "vermelho")
    recuo = 0.25
    largura = 0.05
    passo = 0.088  # folga de 0.038 entre fitas vizinhas
    comprimentos = (1.00, 0.92, 0.98, 0.98, 0.92, 1.00)

    fitas = []
    for i in range(6):
        x = -0.22 + i * passo
        comprimento = comprimentos[i]
        fita = caixa("fita_%d" % i,
                     (x, recuo, topo - comprimento * 0.5),
                     (largura, 0.02, comprimento),
                     cores[i % 3])
        fitas.append((fita, x, topo))
    return fitas


## Move o pivo de cada fita para o topo dela, onde encosta no capacete.
def pivo_no_topo(fitas):
    for fita, x, topo in fitas:
        bpy.context.scene.cursor.location = (x, 0.25, topo)
        bpy.ops.object.select_all(action="DESELECT")
        fita.select_set(True)
        bpy.context.view_layer.objects.active = fita
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)


def juntar_e_exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Junta corpo e capacete numa malha so, mas deixa as fitas de fora: elas
    # precisam continuar sendo nos separados para o Godot poder balanca-las.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type == "MESH" and not obj.name.startswith("fita_"):
            obj.select_set(True)
    corpo = bpy.data.objects.get("camisa")
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.join()

    mestre = bpy.context.active_object
    mestre.name = "Mestre"

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
construir_capacete()
pivo_no_topo(construir_fitas())
juntar_e_exportar()
