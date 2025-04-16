#version 410 core

in  vec2 vTexCoords;
out vec4 fragColor;

uniform sampler2D albedomap; // colors from texture
uniform sampler2D normalmap; // The normal map

void main()
{
	vec3 colors = texture(albedomap,vTexCoords).rgb;
	vec3 normals = texture(normalmap,vTexCoords).rgb;

  if(vTexCoords.y > 0.5){
	  fragColor = vec4(colors, 1.0);
  }else{
	  fragColor = vec4(normals, 1.0);
  }
}
