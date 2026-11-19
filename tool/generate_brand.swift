// Run from the repository root: swift tool/generate_brand.swift
// Approved Quiet Precision identity. Uses macOS CoreGraphics/CoreText only.
import AppKit
import CoreText
import ImageIO

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("design/brand/quiet-precision")
let ink = "191919", white = "FFFFFF", silver = "D7D7D2", stone = "F4F3EF"
let points: [CGPoint] = [(22.0,35.0),(34,68),(49,44),(62,68),(79,30)].map { CGPoint(x:$0.0,y:$0.1) }
// The bundled static font files share a PostScript name. Load each file directly
// instead of resolving by name, which can silently select the wrong weight.
let fonts = Dictionary(uniqueKeysWithValues: ["Inter-Bold", "Inter-Regular"].map { name in
    (name, CGFont(CGDataProvider(url: root.appendingPathComponent("assets/fonts/\(name).ttf") as CFURL)!)!)
})
func color(_ hex: String) -> CGColor {
    let n = UInt32(hex, radix:16)!
    return CGColor(colorSpace: CGColorSpace(name:CGColorSpace.sRGB)!, components:[CGFloat((n>>16)&255)/255,CGFloat((n>>8)&255)/255,CGFloat(n&255)/255,1])!
}
func write(_ text:String, _ url:URL) throws {
    try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
    try text.write(to:url,atomically:true,encoding:.utf8)
}
func num(_ n:CGFloat)->String { String(format:"%.4f",Double(n)) }
func pathData(_ path:CGPath)->String {
    var s = ""
    path.applyWithBlock { p in
        let e=p.pointee
        func point(_ i:Int)->String { "\(num(e.points[i].x)) \(num(e.points[i].y))" }
        switch e.type {
        case .moveToPoint:s += "M\(point(0)) "
        case .addLineToPoint:s += "L\(point(0)) "
        case .addQuadCurveToPoint:s += "Q\(point(0)) \(point(1)) "
        case .addCurveToPoint:s += "C\(point(0)) \(point(1)) \(point(2)) "
        case .closeSubpath:s += "Z "
        @unknown default:break
        }
    }
    return s
}
struct Shape { let path:CGPath; let fill:String?; let stroke:String?; let width:CGFloat }
struct Canvas {
    let w:CGFloat, h:CGFloat
    var shapes:[Shape] = []
    mutating func path(_ p:CGPath,fill:String?=nil,stroke:String?=nil,width:CGFloat=0) {
        shapes.append(Shape(path:p,fill:fill,stroke:stroke,width:width))
    }
    mutating func rect(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ fill:String,radius:CGFloat=0) {
        path(CGPath(roundedRect:CGRect(x:x,y:y,width:w,height:h),cornerWidth:radius,cornerHeight:radius,transform:nil),fill:fill)
    }
    mutating func mark(_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ foreground:String,background:String?=nil) {
        if let background { rect(x,y,size,size,background,radius:size*0.28) }
        let p=CGMutablePath()
        for (i,pt) in points.enumerated() {
            let v=CGPoint(x:x+pt.x*size/100,y:y+pt.y*size/100)
            if i==0 { p.move(to:v) } else { p.addLine(to:v) }
        }
        path(p,stroke:foreground,width:size*0.075)
    }
    mutating func text(_ text:String,_ x:CGFloat,_ baseline:CGFloat,_ size:CGFloat,_ fill:String,bold:Bool=true) {
        let font=CTFontCreateWithGraphicsFont(fonts[bold ? "Inter-Bold" : "Inter-Regular"]!,size,nil,nil)
        let line=CTLineCreateWithAttributedString(NSAttributedString(string:text,attributes:[NSAttributedString.Key(kCTFontAttributeName as String):font]))
        for item in CTLineGetGlyphRuns(line) as! [CTRun] {
            let count=CTRunGetGlyphCount(item)
            var glyphs=[CGGlyph](repeating:0,count:count), positions=[CGPoint](repeating:.zero,count:count)
            CTRunGetGlyphs(item,CFRange(location:0,length:0),&glyphs)
            CTRunGetPositions(item,CFRange(location:0,length:0),&positions)
            for i in 0..<count {
                if let glyph=CTFontCreatePathForGlyph(font,glyphs[i],nil) {
                    var t=CGAffineTransform(a:1,b:0,c:0,d:-1,tx:x+positions[i].x,ty:baseline-positions[i].y)
                    path(glyph.copy(using:&t)!,fill:fill)
                }
            }
        }
    }
    mutating func lockup(_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ fg:String,_ bg:String) {
        mark(x,y,size,fg,background:bg)
        text("ToWork",x+size*1.3,y+size*0.735,size*0.64,bg)
    }
    func svg()->String {
        var s="<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(num(w))\" height=\"\(num(h))\" viewBox=\"0 0 \(num(w)) \(num(h))\" role=\"img\" aria-label=\"ToWork\">\n"
        for a in shapes {
            s += "<path d=\"\(pathData(a.path))\" fill=\"\(a.fill.map { "#"+$0 } ?? "none")\""
            if let stroke=a.stroke { s += " stroke=\"#\(stroke)\" stroke-width=\"\(num(a.width))\" stroke-linecap=\"round\" stroke-linejoin=\"round\"" }
            s += "/>\n"
        }
        return s+"</svg>\n"
    }
    func png(_ url:URL, width:Int?=nil) throws {
        let pw=width ?? Int(w), ph=Int((CGFloat(pw)*h/w).rounded())
        // Supersampling preserves the monoline at 16–48 px.
        let factor = pw <= 256 ? 4 : 1
        let ctx=CGContext(data:nil,width:pw*factor,height:ph*factor,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x:0,y:CGFloat(ph*factor));ctx.scaleBy(x:CGFloat(pw*factor)/w,y:-CGFloat(ph*factor)/h)
        for a in shapes {
            if let fill=a.fill { ctx.addPath(a.path);ctx.setFillColor(color(fill));ctx.fillPath() }
            if let stroke=a.stroke { ctx.addPath(a.path);ctx.setStrokeColor(color(stroke));ctx.setLineWidth(a.width);ctx.setLineCap(.round);ctx.setLineJoin(.round);ctx.strokePath() }
        }
        var image=ctx.makeImage()!
        if factor>1 {
            let small=CGContext(data:nil,width:pw,height:ph,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
            small.interpolationQuality = .high
            small.draw(image,in:CGRect(x:0,y:0,width:pw,height:ph));image=small.makeImage()!
        }
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let dest=CGImageDestinationCreateWithURL(url as CFURL,"public.png" as CFString,1,nil)!
        CGImageDestinationAddImage(dest,image,nil)
        guard CGImageDestinationFinalize(dest) else { fatalError("Failed to export \(url.path)") }
    }
    func save(_ name:String) throws {
        try write(svg(),output.appendingPathComponent(name+".svg"))
        try png(output.appendingPathComponent(name+".png"))
    }
}
// Brand originals: transparent margins, outlined lettering, no external fonts.
for (variant,fg,bg) in [("positive",white,ink),("reverse",ink,white)] {
    var icon=Canvas(w:1024,h:1024);icon.mark(0,0,1024,fg,background:bg);try icon.save("logos/icon-\(variant)")
    var symbol=Canvas(w:1024,h:1024);symbol.mark(0,0,1024,bg);try symbol.save("logos/symbol-\(variant)")
    var horizontal=Canvas(w:960,h:240);horizontal.lockup(24,24,192,fg,bg);try horizontal.save("logos/lockup-horizontal-\(variant)")
    var stacked=Canvas(w:640,h:640);stacked.mark(176,60,288,fg,background:bg);stacked.text("ToWork",104,508,112,bg);try stacked.save("logos/lockup-stacked-\(variant)")
    var wordmark=Canvas(w:760,h:220);wordmark.text("ToWork",20,166,166,bg);try wordmark.save("logos/wordmark-\(variant)")
}
for (variant,bg,fg) in [("light",stone,silver),("dark",ink,"353535")] {
    var pattern=Canvas(w:1440,h:960);pattern.rect(0,0,1440,960,bg)
    for row in 0..<8 { for col in 0..<12 { pattern.mark(CGFloat(col*132-70+(row%2)*66),CGFloat(row*132-40),100,fg) } }
    try pattern.save("patterns/w-rhythm-\(variant)")
    var social=Canvas(w:1200,h:630);social.rect(0,0,1200,630,bg)
    let label=variant=="light" ? ink:white
    social.lockup(72,64,80,bg,label)
    social.text("Make space",72,300,86,label)
    social.text("for what matters.",72,402,86,label)
    social.text("ToWork / Personal workspace",76,552,22,label,bold:false)
    try social.save("social/cover-\(variant)-1200x630")
    var wallpaper=Canvas(w:2560,h:1440);wallpaper.rect(0,0,2560,1440,bg)
    wallpaper.mark(1024,400,512,bg,background:label)
    wallpaper.text("ToWork",1064,1080,116,label)
    try wallpaper.save("wallpapers/desktop-\(variant)-2560x1440")
}
var square=Canvas(w:1024,h:1024);square.rect(0,0,1024,1024,ink);square.mark(0,0,1024,white)
try square.save("app/square-master-1024")
try square.png(output.appendingPathComponent("app/google-play-512.png"),width:512)
var mac=Canvas(w:1024,h:1024);mac.mark(100,100,824,white,background:ink)
try mac.save("app/macos-1024")
let macSet=root.appendingPathComponent("macos/Runner/Assets.xcassets/AppIcon.appiconset")
for n in [16,32,64,128,256,512,1024] { try mac.png(macSet.appendingPathComponent("app_icon_\(n).png"),width:n) }
var legacy=Canvas(w:48,h:48);legacy.mark(2,2,44,white,background:ink)
let res=root.appendingPathComponent("android/app/src/main/res")
for (density,n) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
    try legacy.png(res.appendingPathComponent("mipmap-\(density)/ic_launcher.png"),width:n)
    try legacy.png(output.appendingPathComponent("app/android-legacy-\(n).png"),width:n)
}
// Android masks a 108 dp canvas. Center the original W in its safe region.
// A 0.8 scale gives a 51.6 dp wide mark including the round stroke caps.
var foreground=Canvas(w:108,h:108);foreground.mark(13.6,14.8,80,white)
try foreground.save("app/android-adaptive-foreground")
let vector="""
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M31.2,42.8 L40.8,69.2 L52.8,50 L63.2,69.2 L76.8,38.8"
        android:fillColor="@android:color/transparent" android:strokeColor="#FFFFFF"
        android:strokeWidth="6" android:strokeLineCap="round" android:strokeLineJoin="round" />
</vector>
"""
try write(vector,res.appendingPathComponent("drawable/ic_launcher_foreground.xml"))
try write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources><color name=\"ic_launcher_background\">#191919</color></resources>\n",res.appendingPathComponent("values/ic_launcher_colors.xml"))
for version in [26,33] {
    let mono=version==33 ? "\n    <monochrome android:drawable=\"@drawable/ic_launcher_foreground\" />" : ""
    try write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n    <background android:drawable=\"@color/ic_launcher_background\" />\n    <foreground android:drawable=\"@drawable/ic_launcher_foreground\" />\(mono)\n</adaptive-icon>\n",res.appendingPathComponent("mipmap-anydpi-v\(version)/ic_launcher.xml"))
}
var favicon=Canvas(w:100,h:100);favicon.mark(0,0,100,white,background:ink)
try write(favicon.svg(),output.appendingPathComponent("web/favicon.svg"))
for n in [16,32,48,64,128,180,192,256,512] { try favicon.png(output.appendingPathComponent("web/icon-\(n).png"),width:n) }

// Bundle native handoff assets alongside the SVG/PNG originals.
func copy(_ source:URL,_ dest:URL) throws {
    try FileManager.default.createDirectory(at:dest.deletingLastPathComponent(),withIntermediateDirectories:true)
    try Data(contentsOf:source).write(to:dest,options:.atomic)
}
for n in [16,32,64,128,256,512,1024] {
    try copy(macSet.appendingPathComponent("app_icon_\(n).png"),output.appendingPathComponent("app/macos/AppIcon.appiconset/app_icon_\(n).png"))
}
try copy(macSet.appendingPathComponent("Contents.json"),output.appendingPathComponent("app/macos/AppIcon.appiconset/Contents.json"))
for density in ["mdpi","hdpi","xhdpi","xxhdpi","xxxhdpi"] {
    let relative="mipmap-\(density)/ic_launcher.png"
    try copy(res.appendingPathComponent(relative),output.appendingPathComponent("app/android/res/\(relative)"))
}
for relative in ["drawable/ic_launcher_foreground.xml","values/ic_launcher_colors.xml","mipmap-anydpi-v26/ic_launcher.xml","mipmap-anydpi-v33/ic_launcher.xml"] {
    try copy(res.appendingPathComponent(relative),output.appendingPathComponent("app/android/res/\(relative)"))
}
let iconset=output.appendingPathComponent("app/ToWork.iconset")
for n in [16,32,128,256,512] { for scale in [1,2] {
    let suffix=scale==2 ? "@2x":""
    try copy(macSet.appendingPathComponent("app_icon_\(n*scale).png"),iconset.appendingPathComponent("icon_\(n)x\(n)\(suffix).png"))
} }
let iconutil=Process();iconutil.executableURL=URL(fileURLWithPath:"/usr/bin/iconutil")
iconutil.arguments=["-c","icns",iconset.path,"-o",output.appendingPathComponent("app/ToWork.icns").path]
try iconutil.run();iconutil.waitUntilExit()
guard iconutil.terminationStatus==0 else { fatalError("ICNS export failed") }
var ico=Data(), icoImages=Data(), offset=6+4*16
func byte(_ n:Int) { ico.append(UInt8(n & 255)) }
func little(_ n:Int,_ count:Int) { for i in 0..<count { byte(n >> (i*8)) } }
little(0,2);little(1,2);little(4,2)
for n in [16,32,48,256] {
    let data=try Data(contentsOf:output.appendingPathComponent("web/icon-\(n).png"))
    byte(n==256 ? 0:n);byte(n==256 ? 0:n);byte(0);byte(0)
    little(1,2);little(32,2);little(data.count,4);little(offset,4)
    icoImages.append(data);offset+=data.count
}
ico.append(icoImages);try ico.write(to:output.appendingPathComponent("web/favicon.ico"),options:.atomic)

// A deterministic review sheet, distinct from the Musefold concept board.
var board=Canvas(w:1600,h:1200);board.rect(0,0,1600,1200,stone)
board.text("ToWork",64,100,48,ink);board.text("QUIET PRECISION / BRAND ASSETS",1040,92,20,ink,bold:false)
board.rect(48,150,944,340,white,radius:24);board.lockup(96,226,184,white,ink)
board.text("PRIMARY LOCKUP",96,454,18,ink,bold:false)
board.rect(1016,150,536,340,ink,radius:24);board.mark(1080,202,192,ink,background:white)
board.text("REVERSE",1320,440,18,white,bold:false)
board.text("APP ICONS",64,550,20,ink,bold:false)
board.mark(64,584,192,white,background:ink)
board.text("macOS",64,816,22,ink,bold:false)
board.path(CGPath(ellipseIn:CGRect(x:340,y:584,width:192,height:192),transform:nil),fill:ink)
board.mark(340+(13.6-18)*192/72,584+(14.8-18)*192/72,80*192/72,white)
board.text("Android",340,816,22,ink,bold:false)
for (i,n) in [64,48,32,16].enumerated() { board.mark(CGFloat(610+i*88),650,CGFloat(n),white,background:ink) }
board.text("SMALL SIZES",610,816,18,ink,bold:false)
for (i,c) in [ink,white,silver,stone].enumerated() {
    board.rect(CGFloat(1050+i*120),584,102,132,c,radius:12)
    board.text("#"+c,CGFloat(1050+i*120),756,17,ink,bold:false)
}
board.rect(48,876,728,276,ink,radius:24)
board.text("Make space",88,972,50,white);board.text("for what matters.",88,1034,50,white)
board.text("ToWork",88,1112,22,white,bold:false)
board.rect(800,876,752,276,white,radius:24)
for row in 0..<3 { for col in 0..<8 { board.mark(CGFloat(814+col*92),CGFloat(884+row*80),86,silver) } }
try board.save("brand-overview")
print("Generated Quiet Precision assets and Android/macOS application icons: \(output.path)")
