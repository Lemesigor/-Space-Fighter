#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da cor de cada vértice, definidas em "shader_vertex.glsl" e
// "main.cpp".
in vec4 position_world;
in vec4 normal;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define SPHERE 0
#define SPACE_SHIP 1
#define PLANE  2
#define METEOR 3
#define EGG 4
uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0;
uniform sampler2D TextureImage1;
uniform sampler2D TextureImage2;
uniform sampler2D TextureImage3;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

float ro;
float theta;
float phi;

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;
    vec4 p_modelo = position_model;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);

    // Vetor que define o sentido da reflexão especular ideal.
    vec4 r = -l+(2*n)*dot(n,l);

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;
    float A = 0.0;
    float B = 0.0;

    // Propriedades espectrais da superfície
    vec3 Kd; // Refletância difusa
    vec3 Ks; // Refletância especular
    vec3 Ka; // Refletância ambiente
    float q; // Expoente especular para o modelo de iluminação de Phong

    if (object_id == SPHERE)
    {
        // PREENCHA AQUI as coordenadas de textura da esfera, computadas com
        // projeção esférica EM COORDENADAS DO MODELO. Utilize como referência
        // o slide 139 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        // A esfera que define a projeção deve estar centrada na posição
        // "bbox_center" definida abaixo.

        // Você deve utilizar:
        //   função 'length( )' : comprimento Euclidiano de um vetor
        //   função 'atan( , )' : arcotangente. Veja https://en.wikipedia.org/wiki/Atan2.
        //   função 'asin( )'   : seno inverso.
        //   constante M_PI
        //   variável position_model

        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

        ro = sqrt(p_modelo[0]*p_modelo[0]+p_modelo[1]*p_modelo[1]+p_modelo[2]*p_modelo[2]);
        theta = atan(p_modelo[0], p_modelo[2]);
        phi = asin(p_modelo[1]/ro);

        U = (theta + M_PI)/ (2 * M_PI);
        V = (phi + M_PI_2)/ M_PI;
    }
    else if (object_id == SPACE_SHIP)
    {
        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

        ro = sqrt(p_modelo[0]*p_modelo[0]+p_modelo[1]*p_modelo[1]+p_modelo[2]*p_modelo[2]);
        theta = atan(p_modelo[0], p_modelo[2]);
        phi = asin(p_modelo[1]/ro);

        U = (theta + M_PI)/ (2 * M_PI);
        V = (phi + M_PI_2)/ M_PI;

        Ka = vec3(0.01,0.01,0.01);
    }
    else if (object_id == PLANE)
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        Kd = vec3(0.1,0.1,0.1);
        Ks = vec3(0.2,0.2,0.2);
        Ka = vec3(0.01,0.01,0.01);
        q = 30.0;
        U = texcoords.x;
        V = texcoords.y;
    }
    else if (object_id == METEOR)
    {
        // PREENCHA AQUI as coordenadas de textura da vaca, computadas com
        // projeção planar XY em COORDENADAS DO MODELO. Utilize como referência
        // o slide 106 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf",
        // e também use as variáveis min*/max* definidas abaixo para normalizar
        // as coordenadas de textura U e V dentro do intervalo [0,1]. Para
        // tanto, veja por exemplo o mapeamento da variável 'h' no slide 149 do
        // documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".

        float minx = bbox_min.x;
        float maxx = bbox_max.x;

        float miny = bbox_min.y;
        float maxy = bbox_max.y;

        float minz = bbox_min.z;
        float maxz = bbox_max.z;

        U = (p_modelo[0]-minx)/(maxx - minx);
        V = (p_modelo[1]-miny)/(maxy - miny);
    }


    // Obtemos a refletância difusa a partir da leitura da imagem TextureImage_n
    vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
    vec3 Kd1 = texture(TextureImage1, vec2(U,V)).rgb;
    vec3 Kd2 = texture(TextureImage2, vec2(U,V)).rgb;
    vec3 Kd3 = texture(TextureImage3, vec2(U,V)).rgb;

    // Equação de Iluminação
    float lambert = max(0,dot(n,l));

    // Modelo de iluminação de Phong
    float phong_specular_term  = pow(float(max(0.0f,dot(r,v))),q);

    // Espectro da fonte de iluminação
    vec3 light_spectrum = vec3(1.0,1.0,1.0);

    // Espectro da luz ambiente
    vec3 ambient_light_spectrum = vec3(0.5,0.5,0.5);

    if(object_id == METEOR)                                 // Iluminação difusa com ambiente
    {
        color = Kd0 * light_spectrum * lambert
              + Ka * ambient_light_spectrum;
    }

    else if(object_id == PLANE)                             // Iluminação difusa sem ambiente
    {
        color = Kd1 * light_spectrum * lambert;
    }

    else if (object_id == SPACE_SHIP)                       // Iluninação de Phong
    {
        color = Kd2 * light_spectrum * lambert
              + Ka * ambient_light_spectrum
              + Ks * light_spectrum * phong_specular_term;
    }
    else if(object_id == SPHERE)                            // Iluninação de Phong
    {
        color = Kd1 * light_spectrum * lambert
              + Ka * ambient_light_spectrum
              + Ks * light_spectrum * phong_specular_term;
    }



    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    color = pow(color, vec3(1.0,1.0,1.0)/2.2);
}
