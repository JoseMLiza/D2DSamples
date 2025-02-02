VERSION 5.00
Begin VB.Form frmMain 
   AutoRedraw      =   -1  'True
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Save image"
   ClientHeight    =   5445
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   6045
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   363
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   403
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

' // Manipulate bits and save image to PNG using WIC

Option Explicit

Private Const GENERIC_READ      As Long = &H80000000
Private Const GENERIC_WRITE     As Long = &H40000000
Private Const FADF_AUTO         As Long = 1

Private Type SAFEARRAY
    cDims       As Integer
    fFeatures   As Integer
    cbElements  As Long
    cLocks      As Long
    pvData      As Long
    Bounds      As SAFEARRAYBOUND
End Type

Private Declare Sub CopyMemory Lib "kernel32" _
                    Alias "RtlMoveMemory" ( _
                    ByRef Destination As Any, _
                    ByRef Source As Any, _
                    ByVal Length As Long)
Private Declare Sub MoveArray Lib "msvbvm60" _
                    Alias "__vbaAryMove" ( _
                    ByRef Destination() As Any, _
                    ByRef Source As Any)


Dim cRenderTarget   As ID2D1DCRenderTarget
Dim cFactory        As ID2D1Factory
    
Private Sub Form_Load()
    Dim tRect       As RECT
   
    ' // Create a factory
    Set cFactory = D2D1.CreateFactory()

    ' // Create render target
    Set cRenderTarget = cFactory.CreateDCRenderTarget(D2D1.RenderTargetProperties( _
                        D2D1.PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED)))
    
    tRect.Right = Me.ScaleWidth
    tRect.bottom = Me.ScaleHeight
    
    ' // Bind form DC with render target
    cRenderTarget.BindDC Me.hDC, tRect
                            
    ' // Draw buttons to window
    DrawButtons cRenderTarget
    
    ' // Save image to PNG
    SaveBitmap

End Sub

' // Draw buttons and save picture to PNG
Private Sub SaveBitmap()
    Dim cWicFactory As IWICImagingFactory
    Dim cWicStream  As IWICStream
    Dim cEncoder    As IWICBitmapEncoder
    Dim cFrame      As IWICBitmapFrameEncode
    Dim cBitmap     As IWICBitmap
    Dim cBitmapSurf As ID2D1RenderTarget
    Dim cD2DBitmap  As ID2D1Bitmap
    Dim cLock       As IWICBitmapLock
    Dim lColumn     As Long
    Dim lComponent  As Long
    Dim bPixels()   As Byte
    Dim lStride     As Long
    Dim tPixDesc    As SAFEARRAY
    Dim lWidth      As Long
    
    Set cWicFactory = New WICVBLib.WICImagingFactory
    
    ' // Create WIC bitmap that is saved to file
    Set cBitmap = cWicFactory.CreateBitmap(Me.ScaleWidth, Me.ScaleHeight, _
                                           WIC.GUID_WICPixelFormat32bppPBGRA, WICBitmapCacheOnLoad)

    ' // Create render target based on that image
    Set cBitmapSurf = cFactory.CreateWicBitmapRenderTarget(cBitmap, D2D1.RenderTargetProperties( _
                        D2D1.PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED), _
                        D2D1_RENDER_TARGET_TYPE_SOFTWARE, 96, 96, D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE))
    
    DrawButtons cBitmapSurf

    ' // Inverse half pixels
    Set cLock = cBitmap.Lock(WIC.WICRect(0, 0, Me.ScaleWidth, Me.ScaleHeight / 2), WICBitmapLockWrite)
    
    ' // Get stride (num of bytes between each scanlines)
    lStride = cLock.GetStride
    
    ' // Get size
    cLock.GetSize lWidth, 0
    
    ' // Don't copy data to array, manipulate directly
    tPixDesc.cbElements = 1
    tPixDesc.cDims = 1
    tPixDesc.fFeatures = FADF_AUTO
    
    ' // Get pointer
    cLock.GetDataPointer tPixDesc.Bounds.cElements, tPixDesc.pvData
    
    ' // Make VB-array from descriptor
    MoveArray bPixels(), VarPtr(tPixDesc)
    
    ' // Go thru each scanline
    Do While lComponent <= UBound(bPixels)
        
        For lColumn = 0 To lWidth * 4 - 1
            
            ' // Go thru each pixel's component
            If lColumn Mod 4 <> 3 Then
                ' // Skip alpha component
                bPixels(lComponent + lColumn) = Not bPixels(lComponent + lColumn)
            End If
            
        Next
        
        lComponent = lComponent + lStride
        
    Loop
    
    ' // Unlock
    Set cLock = Nothing
    
    ' // Create stream based on file
    Set cWicStream = cWicFactory.CreateStream

    cWicStream.InitializeFromFilename App.Path & "\out.png", GENERIC_READ Or GENERIC_WRITE
    
    ' // Create PNG encoder
    Set cEncoder = cWicFactory.CreateEncoder(WIC.GUID_ContainerFormatPng, ByVal 0&)
    
    ' // Initialize encoder using file stream
    cEncoder.Initialize cWicStream, WICBitmapEncoderNoCache
    
    ' // Add new frame to image
    cEncoder.CreateNewFrame cFrame, Nothing
    
    cFrame.Initialize Nothing
    
    ' // Write pixels to frame
    cFrame.WriteSource cBitmap, ByVal 0&
    
    ' // Save
    cFrame.Commit
    cEncoder.Commit

End Sub

' // Draw image
Private Sub DrawButtons( _
            ByVal cTarget As ID2D1RenderTarget)
            
    cTarget.BeginDraw
    
    FillBackground cTarget
    
    DrawGlassButton cTarget, 100, 50, 200, 40, 20, &H8DEAFB, &HE3365
    
    DrawGlassButton cTarget, 120, 150, 150, 60, 2, &HFF0D0D, &H771A1A
    
    DrawGlassButton cTarget, 150, 250, 80, 80, 40, &HFB70&, &H24C1F
    
    cTarget.EndDraw ByVal 0&, ByVal 0&
    
End Sub

' //
Private Sub DrawGlassButton( _
            ByVal cTarget As ID2D1RenderTarget, _
            ByVal fX As Single, _
            ByVal fY As Single, _
            ByVal fWidth As Single, _
            ByVal fHeight As Single, _
            ByVal fRadius As Single, _
            ByVal lColor1 As Long, _
            ByVal lColor2 As Long)
    Dim cEdgesBrush     As ID2D1LinearGradientBrush
    Dim cEdgesGradColl  As ID2D1GradientStopCollection
    Dim cBackBrush      As ID2D1RadialGradientBrush
    Dim cBackGradColl   As ID2D1GradientStopCollection
    Dim cSpecBrush      As ID2D1LinearGradientBrush
    Dim cSpecGradColl   As ID2D1GradientStopCollection
    Dim tGrad(1)        As D2D1_GRADIENT_STOP

    ' // Create gradient colors collection and brush for edges
    tGrad(0) = D2D1.GradientStop(0, D2D1.ColorF(&H2F2C2B))
    tGrad(1) = D2D1.GradientStop(1, D2D1.ColorF(White))

    Set cEdgesGradColl = cTarget.CreateGradientStopCollection(tGrad(0), 2, D2D1_GAMMA_1_0, D2D1_EXTEND_MODE_CLAMP)
    Set cEdgesBrush = cTarget.CreateLinearGradientBrush(D2D1.LinearGradientBrushProperties(D2D1.Point2F(0, 0), _
                            D2D1.Point2F(0, fHeight)), ByVal 0&, cEdgesGradColl)
                                                  
    ' // Create gradient colors collection and brush for background
    tGrad(0) = D2D1.GradientStop(1, D2D1.ColorF(lColor2))
    tGrad(1) = D2D1.GradientStop(0, D2D1.ColorF(lColor1))

    Set cBackGradColl = cTarget.CreateGradientStopCollection(tGrad(0), 2, D2D1_GAMMA_2_2, D2D1_EXTEND_MODE_CLAMP)
    Set cBackBrush = cTarget.CreateRadialGradientBrush(D2D1.RadialGradientBrushProperties( _
                            D2D1.Point2F(fWidth / 2, fHeight), _
                            D2D1.Point2F(0, 0), fWidth, fHeight * 0.75), ByVal 0&, cBackGradColl)

    ' // Create specular gradient
    tGrad(0) = D2D1.GradientStop(0, D2D1.ColorF(White))
    tGrad(1) = D2D1.GradientStop(1, D2D1.ColorF(White, 0))
    
    Set cSpecGradColl = cTarget.CreateGradientStopCollection(tGrad(0), 2, D2D1_GAMMA_2_2, D2D1_EXTEND_MODE_CLAMP)
    Set cSpecBrush = cTarget.CreateLinearGradientBrush(D2D1.LinearGradientBrushProperties(D2D1.Point2F(0, 0), _
                            D2D1.Point2F(0, fHeight * 0.575)), ByVal 0&, cSpecGradColl)
                          
    cSpecBrush.SetOpacity 0.8

    
    ' // Offset to right
    cTarget.SetTransform D2D1.Matrix3x2F_Translation2(fX, fY)
    
    ' // Draw sunked edges
    cTarget.DrawRoundedRectangle D2D1.RoundedRect(D2D1.RectF(1, 0, fWidth - 1, fHeight), _
                                       fRadius, fRadius), cEdgesBrush, 3
    
    ' // Fill background
    cTarget.FillRoundedRectangle D2D1.RoundedRect(D2D1.RectF(0, 0, fWidth, fHeight), _
                                       fRadius, fRadius), cBackBrush
    
    ' // Apply clip
    cTarget.PushAxisAlignedClip D2D1.RectF(0, 0, fWidth, fHeight / 2), D2D1_ANTIALIAS_MODE_ALIASED
        
    ' // Draw specular
    cTarget.FillRoundedRectangle D2D1.RoundedRect(D2D1.RectF(3, 1, fWidth - 3, fHeight), _
                                       fRadius, fRadius), cSpecBrush
    
    cTarget.PopAxisAlignedClip

End Sub

' // Fill background
Private Sub FillBackground( _
            ByVal cTarget As ID2D1RenderTarget)
    Dim cMemSurface As ID2D1BitmapRenderTarget
    Dim cBrush      As ID2D1Brush
    Dim cPattern    As ID2D1BitmapBrush
    Dim cVignette   As ID2D1RadialGradientBrush
    Dim cGradient   As ID2D1GradientStopCollection
    Dim tPoints(1)  As D2D1_GRADIENT_STOP
    
    ' // Create chess pattern
    Set cMemSurface = cTarget.CreateCompatibleRenderTarget(D2D1.SizeF(32, 32), ByVal 0&, ByVal 0&, _
                      D2D1_COMPATIBLE_RENDER_TARGET_OPTIONS_NONE)
    
    cMemSurface.BeginDraw
    

    Set cBrush = cMemSurface.CreateSolidColorBrush(D2D1.ColorF(&H8CBBA1), ByVal 0&)
    
    cMemSurface.FillRectangle D2D1.RectF(0, 0, 16, 16), cBrush
    cMemSurface.FillRectangle D2D1.RectF(16, 16, 32, 32), cBrush

    cMemSurface.EndDraw ByVal 0&, ByVal 0&
    
    Set cPattern = cMemSurface.CreateBitmapBrush(cMemSurface.GetBitmap, _
                   D2D1.BitmapBrushProperties(D2D1_EXTEND_MODE_WRAP, D2D1_EXTEND_MODE_WRAP), _
                   D2D1.BrushProperties(0.5, D2D1.Matrix3x2F_Rotation2(45, 0, 0)))
    
    ' // Set background
    cTarget.Clear D2D1.ColorF(Honeydew)
    
    cTarget.FillRectangle D2D1.RectF(0, 0, Me.ScaleWidth, Me.ScaleHeight), cPattern
    
    ' // Make vignette
    tPoints(0) = D2D1.GradientStop(1, D2D1.ColorF(Black))
    tPoints(1) = D2D1.GradientStop(0, D2D1.ColorF(White, 0))
    
    Set cGradient = cTarget.CreateGradientStopCollection(tPoints(0), 2, D2D1_GAMMA_2_2, D2D1_EXTEND_MODE_CLAMP)
    Set cVignette = cTarget.CreateRadialGradientBrush(D2D1.RadialGradientBrushProperties( _
                                    D2D1.Point2F(Me.ScaleWidth / 2, Me.ScaleHeight / 2), _
                                    D2D1.Point2F(0, 0), Me.ScaleWidth / 1.5, Me.ScaleHeight / 1.5), ByVal 0&, cGradient)
                                                                   
    cVignette.SetOpacity 0.5
    
    cTarget.FillRectangle D2D1.RectF(0, 0, Me.ScaleWidth, Me.ScaleHeight), cVignette
    
End Sub
