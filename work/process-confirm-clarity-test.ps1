$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$drawingCommon=[System.Drawing.Bitmap].Assembly.Location
$drawingPrimitives=[System.Drawing.Color].Assembly.Location
$drawingGdiPlus=[System.Reflection.Assembly]::Load('System.Private.Windows.GdiPlus').Location
$drawingCore=[System.Reflection.Assembly]::Load('System.Private.Windows.Core').Location

Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Text;

public static class ConfirmClarityProcessor {
    static readonly Color[] P={ColorTranslator.FromHtml("#090807"),ColorTranslator.FromHtml("#15110F"),ColorTranslator.FromHtml("#241A16"),ColorTranslator.FromHtml("#3A2720"),ColorTranslator.FromHtml("#5A191D"),ColorTranslator.FromHtml("#8E2C31"),ColorTranslator.FromHtml("#B56A36"),ColorTranslator.FromHtml("#D0A05A"),ColorTranslator.FromHtml("#D8C6A5"),ColorTranslator.FromHtml("#786B5C"),ColorTranslator.FromHtml("#5FA86B")};
    static Color Snap(Color c){int best=Int32.MaxValue;Color win=P[0];foreach(Color p in P){int r=c.R-p.R,g=c.G-p.G,b=c.B-p.B,d=r*r+g*g+b*b;if(d<best){best=d;win=p;}}return Color.FromArgb(255,win.R,win.G,win.B);}
    static bool Bg(Color c){int max=Math.Max(c.R,Math.Max(c.G,c.B)),min=Math.Min(c.R,Math.Min(c.G,c.B)),avg=(c.R+c.G+c.B)/3;return c.A<128||max<=22||avg>=248||(max-min<=10&&avg>=105);}
    public static void Export(string sourcePath,string outputPath){
        using(var src=new Bitmap(sourcePath)){int w=src.Width,h=src.Height;bool[,] mask=new bool[w,h];int[] qx=new int[w*h],qy=new int[w*h];int head=0,tail=0;
            for(int x=0;x<w;x++){if(Bg(src.GetPixel(x,0))){mask[x,0]=true;qx[tail]=x;qy[tail++]=0;}if(!mask[x,h-1]&&Bg(src.GetPixel(x,h-1))){mask[x,h-1]=true;qx[tail]=x;qy[tail++]=h-1;}}
            for(int y=0;y<h;y++){if(!mask[0,y]&&Bg(src.GetPixel(0,y))){mask[0,y]=true;qx[tail]=0;qy[tail++]=y;}if(!mask[w-1,y]&&Bg(src.GetPixel(w-1,y))){mask[w-1,y]=true;qx[tail]=w-1;qy[tail++]=y;}}
            int[] dx={1,-1,0,0},dy={0,0,1,-1};while(head<tail){int px=qx[head],py=qy[head++];for(int i=0;i<4;i++){int x=px+dx[i],y=py+dy[i];if(x>=0&&y>=0&&x<w&&y<h&&!mask[x,y]&&Bg(src.GetPixel(x,y))){mask[x,y]=true;qx[tail]=x;qy[tail++]=y;}}}
            using(var clean=new Bitmap(w,h,PixelFormat.Format32bppArgb)){int l=w,t=h,r=-1,b=-1;for(int y=0;y<h;y++)for(int x=0;x<w;x++){if(mask[x,y])continue;clean.SetPixel(x,y,Snap(src.GetPixel(x,y)));if(x<l)l=x;if(x>r)r=x;if(y<t)t=y;if(y>b)b=y;}
                int cw=r-l+1,ch=b-t+1;using(var grid=new Bitmap(48,48,PixelFormat.Format32bppArgb)){double s=Math.Min(46.0/cw,46.0/ch);int dw=Math.Max(1,(int)Math.Round(cw*s)),dh=Math.Max(1,(int)Math.Round(ch*s)),ox=(48-dw)/2,oy=(48-dh)/2;
                    for(int y=0;y<dh;y++){int sy=t+Math.Min(ch-1,(int)((long)y*ch/dh));for(int x=0;x<dw;x++){int sx=l+Math.Min(cw-1,(int)((long)x*cw/dw));grid.SetPixel(ox+x,oy+y,clean.GetPixel(sx,sy));}}
                    using(var final=new Bitmap(96,96,PixelFormat.Format32bppArgb)){for(int y=0;y<96;y++)for(int x=0;x<96;x++)final.SetPixel(x,y,grid.GetPixel(x/2,y/2));final.Save(outputPath,ImageFormat.Png);}}}}
    }
    static void Draw(Graphics g,Bitmap image,int x,int y,int size){g.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;g.PixelOffsetMode=System.Drawing.Drawing2D.PixelOffsetMode.Half;g.DrawImage(image,new Rectangle(x,y,size,size));}
    public static void Compare(string oldPath,string newPath,string outputPath){using(var sheet=new Bitmap(760,260,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(sheet))using(var oldIcon=new Bitmap(oldPath))using(var newIcon=new Bitmap(newPath))using(var title=new Font("Consolas",20,FontStyle.Bold,GraphicsUnit.Pixel))using(var label=new Font("Consolas",14,FontStyle.Regular,GraphicsUnit.Pixel))using(var ivory=new SolidBrush(P[8]))using(var muted=new SolidBrush(P[9])){g.Clear(P[0]);g.TextRenderingHint=TextRenderingHint.SingleBitPerPixelGridFit;g.DrawString("CONFIRM ICON — SMALL-SIZE TEST",title,ivory,24,18);g.DrawString("ORIGINAL",label,muted,35,62);g.DrawString("ICON-FIRST",label,muted,405,62);Draw(g,oldIcon,35,90,96);Draw(g,oldIcon,175,118,32);Draw(g,oldIcon,250,122,24);Draw(g,newIcon,405,90,96);Draw(g,newIcon,545,118,32);Draw(g,newIcon,620,122,24);g.DrawString("96px",label,ivory,35,198);g.DrawString("32px",label,ivory,170,160);g.DrawString("24px",label,ivory,245,160);g.DrawString("96px",label,ivory,405,198);g.DrawString("32px",label,ivory,540,160);g.DrawString("24px",label,ivory,615,160);sheet.Save(outputPath,ImageFormat.Png);}}
}
'@ -ReferencedAssemblies @($drawingCommon,$drawingPrimitives,$drawingGdiPlus,$drawingCore)

$dir='Dashboards\Control Dashboard\User Interface\assets\control-deck'
$new=Join-Path $dir 'action-confirm-clarity-test.png'
$compare=Join-Path $dir 'action-confirm-clarity-comparison.png'
foreach($path in @($new,$compare)){if(Test-Path -LiteralPath $path){throw "Refusing to overwrite $path"}}
[ConfirmClarityProcessor]::Export('C:\Users\Esthe\.codex\generated_images\01a08cf7-7786-7972-b708-750b4bf309fe\exec-463a114c-a254-4221-85a7-ae489056ecd9.png',$new)
[ConfirmClarityProcessor]::Compare((Join-Path $dir 'action-confirm.png'),$new,$compare)
