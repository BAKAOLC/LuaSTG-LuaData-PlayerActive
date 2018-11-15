texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
	texture = <ScreenTexture>;
	AddressU  = BORDER;
	AddressV = BORDER;
	Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 screen:SCREENSIZE;
float4 viewport:VIEWPORT;

//不兼容的部分
float size < string binding = "_size"; > = 128.0f;//效果半径
float _arg < string binding = "_arg"; > = 1.0f;//效果开关//目前没用上
float unsize < string binding = "size"; > = 1.0f;//兼容性接口……
//兼容的部分
float4 color < string binding = "color"; > = float4(1.0, 1.0, 0.0, 0.0);
float timer < string binding = "timer"; > = 0.0f;
float centerx < string binding = "centerX"; > = 0.0f;
float centery < string binding = "centerY"; > = 0.0f;

float toarg(float unreal)//兼容性接口……
{
	float rate = (screen.w - screen.y) / 480;
	unreal=unreal/(200*128);
	unreal=(unreal*1000)/7;
	unreal=unreal/rate;
	return unreal;
}

float4 multiply(float4 base, float4 blend)
{
	float4 c;
	c.r = blend.r * base.r;
	c.g = blend.g * base.g;
	c.b = blend.b * base.b;
	c.a = base.a;//1.0-(1.0-base.a)*(1.0-blend.a);
	return c;
}

float4 overlay(float4 base, float4 blend)
{
	float4 c;
	
	if (base.r<=0.5)
	{
		c.r=2.0*blend.r*base.r;
	}
	else
	{
		c.r=1.0-2.0*(1.0-blend.r)*(1.0-base.r);
	}
	if (base.g<=0.5)
	{
		c.g=2.0*blend.g*base.g;
	}
	else
	{
		c.g=1.0-2.0*(1.0-blend.g)*(1.0-base.g);
	}
	if (base.b<=0.5)
	{
		c.b=2.0*blend.b*base.b;
	}
	else
	{
		c.b=1.0-2.0*(1.0-blend.b)*(1.0-base.b);
	}
	c.a = base.a;//1.0-(1.0-base.a)*(1.0-blend.a);
	return c;
}

float mylerp(float x)
{
	if (x >= 0.5)
	{
		x = 1 - 2 * pow((x-1),2);
	}
	else
	{
		x = 2 * pow(x,2);
	}
	return x;
	
}

float mylerp2(float x)
{
	if (x >= 0.2622)
	{
		x = 1 - 2 * pow((x-1),4);
	}
	else
	{
		x = 5.9255 * pow(x,2);
	}
	return x;
	
}

float2 sinwave(float amplitude, float cycle, float phase, float2 xy, float rate)
{
	float2 wave=
		//float2(rate*(amplitude/2)*cos(radians(     cycle*(xy.x/rate) + 8*timer) ), 0) +
		//float2(rate*(amplitude/4)*cos(radians( (cycle/2)*(xy.x/rate) + 8*timer) ), 0) +
		float2(0, -8*rate) +
		
		float2(0, rate*    amplitude*sin(radians(cycle*(xy.x/rate) + (cycle/2)*(-xy.y/rate) + phase) ) ) +//斜方向振动，短周期
		float2(0, rate*(amplitude/2)*sin(radians((cycle/2)*(xy.x/rate) + phase) ) )  //竖直方向振动，长周期，振幅减半
	;
	return wave;
}

struct PS_INPUT{
	float4 position:POSITION;
	float2 uv:TEXCOORD0;
	float2 vpos:VPOS;
};

struct PS_OUTPUT{
	float4 color:COLOR0;
};

PS_OUTPUT ps_wave(PS_INPUT In):COLOR
{
	float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
	float rate = (screen.w - screen.y) / 480;
	float size2 = size*rate;
	float2 xy = In.uv * screenSize;
	float2 xy2 = xy;
	float2 center = float2(centerx, centery);
	float2 delta = xy - center;
	float len = length(delta);
	float arg=toarg(unsize);//兼容性接口……
	
	//第一次扭曲，波纹扭曲
	float2 wave = sinwave(6.0, 6.0, 8*timer, xy, rate);
	if (len <= size2){
		float k1 = (size2 - len) / size2;
		xy = xy + lerp(float2(0,0), wave, mylerp2(k1));
	}
	
	//重新计算相对中心的向量
	delta = xy - center;
	len = length(delta);
	
	//第二次扭曲，透镜效果
	if (len <= size2){
		float k1 = (size2 - len) / size2;
		xy = center + lerp(delta, 0.4*delta, mylerp2(k1));
	}
	
	//采样范围限制
	xy = float2(clamp(xy.x, viewport.x+1.0, viewport.z-1.0), clamp(xy.y, viewport.y+1.0, viewport.w-1.0));
	xy = lerp(xy2, xy, clamp(arg, 0.0, 1.0));
	
	//采样
	In.uv = xy / screenSize;
	float4 texColor = tex2D(ScreenTextureSampler, In.uv);
	float4 texColor2 = texColor;
	
	//颜色叠加
	if (len < size2){
		float k1 = (size2 - len) / size2;
		//texColor = lerp(texColor, multiply(texColor, color), mylerp2(k1));
		texColor = lerp(texColor, overlay(texColor, color), mylerp2(k1));
	}
	texColor = lerp(texColor2, texColor, clamp(arg, 0.0, 1.0));
	texColor.a = 1;
	
	PS_OUTPUT Out;
	Out.color=texColor;
	return Out;
}

technique Main
{
	pass wave
	{
		PixelShader = compile ps_3_0 ps_wave();
	}
}
