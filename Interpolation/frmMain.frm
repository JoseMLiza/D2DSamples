VERSION 5.00
Begin VB.Form frmMain 
   Caption         =   "Form1"
   ClientHeight    =   3600
   ClientLeft      =   120
   ClientTop       =   450
   ClientWidth     =   4710
   LinkTopic       =   "Form1"
   ScaleHeight     =   3600
   ScaleWidth      =   4710
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim mcFactory       As ID2D1Factory
Dim mcHwndTarget    As ID2D1HwndRenderTarget
Dim mcMemTarget     As ID2D1BitmapRenderTarget

Private Sub Form_Load()
    Dim cBrush  As ID2D1SolidColorBrush
    
    Me.ScaleMode = vbPixels
    
    Set mcFactory = D2D1.CreateFactory()
    
    Set mcHwndTarget = mcFactory.CreateHwndRenderTarget(D2D1.RenderTargetProperties(D2D1.PixelFormat()), _
                                                        D2D1.HwndRenderTargetProperties( _
                                                        Me.hWnd, D2D1.SizeU(100, 100)))
    Set mcMemTarget = mcHwndTarget.CreateCompatibleRenderTarget(ByVal 0&, ByVal 0&, ByVal 0&, D2D1_COMPATIBLE_RENDER_TARGET_OPTIONS_NONE)
    
    Set cBrush = mcMemTarget.CreateSolidColorBrush(D2D1.ColorF(BurlyWood), ByVal 0&)
    
    ' // Paint to mem target
    mcMemTarget.BeginDraw
    
    mcMemTarget.DrawEllipse D2D1.Ellipse(D2D1.Point2F(30, 30), 15, 15), cBrush, 3
    mcMemTarget.DrawLine 0, 0, 80, 90, cBrush
    
    mcMemTarget.EndDraw ByVal 0&, ByVal 0&
    
End Sub

Private Sub Form_Paint()
    
    ' // Draw to hwnd
    mcHwndTarget.BeginDraw
    
    mcHwndTarget.DrawBitmap mcMemTarget.GetBitmap, D2D1.RectF(0, 0, Me.ScaleWidth, Me.ScaleHeight), _
                            , D2D1_BITMAP_INTERPOLATION_MODE_LINEAR, ByVal 0&
    
    mcHwndTarget.EndDraw ByVal 0&, ByVal 0&
    
End Sub

Private Sub Form_Resize()
    mcHwndTarget.Resize D2D1.SizeU(Me.ScaleWidth, Me.ScaleHeight)
End Sub
