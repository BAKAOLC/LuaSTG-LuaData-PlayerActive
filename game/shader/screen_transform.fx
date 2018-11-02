//======================================
//code by Xiliusha(ETC)
//震屏特效的另一种实现
//======================================

// 由PostEffect过程捕获到的纹理
texture2D ScreenTexture:POSTEFFECTTEXTURE;//纹理
sampler2D ScreenTextureSampler = sampler_state//采样器
{
	texture = <ScreenTexture>;
	AddressU  = BORDER;
	AddressV = BORDER;
	Filter = MIN_MAG_LINEAR_MIP_POINT;
};

// 自动设置的参数
float4 screen : SCREENSIZE;  // 屏幕缓冲区大小

// 外部参数
float DX < string binding = "dx"; > = 0.0f;
float DY < string binding = "dy"; > = 0.0f;
float Scale < string binding = "scale"; > = 1.0f;//屏幕缩放

//world视口
float vx < string binding = "vx"; > = -1.0f;
float vy < string binding = "vy"; > = -1.0f;
float vz < string binding = "vz"; > = -1.0f;
float vw < string binding = "vw"; > = -1.0f;
float inner = 1.0f;

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
	float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
	float2 xy = uv * screenSize;//屏幕上真实位置
	float2 move = Scale * float2(DX, DY);
	
	if (vx==-1.0f)
	{
		xy=xy-move;//不提供视口参数时
	}
	else
	{
		if (xy.x>=vx && xy.x<=vz && xy.y>=vy && xy.y<=vw)
		{
			xy=xy-move;
			xy.x=clamp(xy.x,vx+inner,vz-inner);
			xy.y=clamp(xy.y,vy+inner,vw-inner);
		}
	}
	
	uv=xy/screenSize;//转换为uv坐标
	
	float4 texColor = tex2D(ScreenTextureSampler, uv);//对纹理进行采样
	
	texColor.a = 1;
	return texColor;
}

technique Main
{
	pass MainPass
	{
		PixelShader = compile ps_3_0 PS_MainPass();
	}
}
