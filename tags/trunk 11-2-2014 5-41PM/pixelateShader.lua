local pixelate = {}

pixelate.shader = love.graphics.newShader[[

extern vec2 screen;
extern number time;
extern number imgTime;
extern number startingPixSize;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
   float pixelSize = startingPixSize - ((startingPixSize - 1.) / imgTime * time);
   
   if (pixelSize < 1.)
   {
      pixelSize = 1.;
   }
   
   float dx = pixelSize * (1. / screen.x); //normalized pixelsize on the width
   float dy = pixelSize * (1. / screen.y); //normalized pixelsize on the height
   
   vec2 coord = vec2(dx * (floor(texture_coords.x / dx) +.5), dy * (floor(texture_coords.y / dy) + .5));
   //vec2 coord = vec2(dx * (floor(texture_coords.x / dx)), dy * (floor(texture_coords.y / dy)));
   return Texel(texture, coord);
}
]]

return pixelate