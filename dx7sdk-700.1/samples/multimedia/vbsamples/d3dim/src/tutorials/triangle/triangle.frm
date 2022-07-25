VERSION 5.00
Begin VB.Form Form1 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "TriangleVB"
   ClientHeight    =   3570
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   3810
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   238
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   254
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Const pi As Single = 3.141592

Dim g_dx As New DirectX7
Dim g_dd As DirectDraw7
Dim g_ddsd As DDSURFACEDESC2
Dim g_ddsPrimary As DirectDrawSurface7, _
    g_ddsBackBuffer As DirectDrawSurface7
Dim g_d3d As Direct3D7
Dim g_d3dDevice As Direct3DDevice7
Dim g_TriangleVert(5) As D3DVERTEX
Dim g_rcDest As RECT, _
    g_rcSrc As RECT
Dim g_d3drcViewport(0) As D3DRECT
Dim g_bRunning As Boolean

Private Sub Form_Load()
    Dim CNT As Single
    Dim j As Long

    ' Initialize the DirectDraw and Direct3D objects that this
    ' sample application will use to render and display the triangle.
    InitDDraw
    InitD3D
    InitGeometry
    
    Me.Show
    
    g_bRunning = True
    Do While g_bRunning = True
        CNT = CNT + 1
        RenderScene
        FrameMove (CNT / 360)
        
        g_dx.GetWindowRect Me.hWnd, g_rcDest
    
        j = g_ddsPrimary.Blt(g_rcDest, g_ddsBackBuffer, g_rcSrc, DDBLT_WAIT)
        If j <> DD_OK Then
            MsgBox "Couldn't copy the source rectangle to the destination surface." & Chr$(13) & Hex(j)
            End
        End If
        DoEvents
    Loop
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Spin the triangle
'
'   For this simple tutorial, we are just rotating the triangle about the y-axis.
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub FrameMove(stepVal As Single)
    Dim matSpinY As D3DMATRIX

    Call g_dx.RotateYMatrix(matSpinY, stepVal)
    Call g_d3dDevice.SetTransform(D3DTRANSFORMSTATE_WORLD, matSpinY)
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' Render the scene
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub RenderScene()
    ' Clear the viewport to a blue color.
    g_d3dDevice.Clear 1, g_d3drcViewport(), D3DCLEAR_TARGET, &HFF, 0, 0
    
    ' Begin the scene, render the triangle, then complete the scene
    g_d3dDevice.BeginScene
        Call g_d3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, D3DFVF_VERTEX, _
                                       g_TriangleVert(0), 6, D3DDP_DEFAULT)
    g_d3dDevice.EndScene
End Sub

Private Sub Form_Unload(Cancel As Integer)
    g_bRunning = False
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' Initalize DirectDraw
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub InitDDraw()
    ' Create the DirectDraw object and set the application
    ' cooperative level.
    Set g_dd = g_dx.DirectDrawCreate("")
    
    g_dd.SetCooperativeLevel Me.hWnd, DDSCL_NORMAL
    
    ' Prepare and create the primary surface.
    g_ddsd.lFlags = DDSD_CAPS
    g_ddsd.ddsCaps.lCaps = DDSCAPS_PRIMARYSURFACE
    
    Set g_ddsPrimary = g_dd.CreateSurface(g_ddsd)
    
    ' Now create the render-target surface. We are reusing g_ddsd here.
    g_ddsd.lFlags = DDSD_HEIGHT Or DDSD_WIDTH Or DDSD_CAPS
    g_ddsd.ddsCaps.lCaps = DDSCAPS_OFFSCREENPLAIN Or DDSCAPS_3DDEVICE
    
    ' Use the size of the form to determine the size of the render target
    ' and viewport rectangle.
    g_dx.GetWindowRect Me.hWnd, g_rcDest
    
    ' Set the dimensions of the surface description
    g_ddsd.lWidth = g_rcDest.Right - g_rcDest.Left
    g_ddsd.lHeight = g_rcDest.Bottom - g_rcDest.Top
    
    ' Create the render-target surface
    Set g_ddsBackBuffer = g_dd.CreateSurface(g_ddsd)
        
    ' Cache the dimensions of the render target. We'll use
    ' it for blitting operations.
    With g_rcSrc
        .Left = 0: .Top = 0
        .Bottom = g_ddsd.lHeight
        .Right = g_ddsd.lWidth
    End With
    
    ' Create a DirectDrawClipper and attach it to the primary surface.
    Dim pcClipper As DirectDrawClipper
    
    Set pcClipper = g_dd.CreateClipper(0)
    pcClipper.SetHWnd Me.hWnd
    
    g_ddsPrimary.SetClipper pcClipper
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' Initalize Direct3D, including the rendering device, lighting,
' the viewport, and the material
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sub InitD3D()
    Dim d3d As Direct3D7
    Dim ddsd As DDSURFACEDESC2
        
    ' Retrieve a reference to the Direct3D7 class from the
    ' DirectDraw7 object.
    Set d3d = g_dd.GetDirect3D
    
    ' Query DirectDraw for the current display mode. For simplicity, this
    ' does not support palleted display modes (8-bit and lower).
    g_dd.GetDisplayMode ddsd
    
    If ddsd.ddpfPixelFormat.lRGBBitCount <= 8 Then
        MsgBox "This application does not support screen display " & _
               "modes lower than 16-bit."
        End
    End If
    
    '
    ' Create the device. The GUID is hardcoded for now, but should come from
    ' device enumeration, which is the topic of a future tutorial. The device
    ' is created off of our back buffer, which becomes the render target for
    ' the newly created device.
    '
    Set g_d3dDevice = d3d.CreateDevice("IID_IDirect3DHALDevice", g_ddsBackBuffer)
    
    ' Define the viewport rectangle.
    Dim VPDesc As D3DVIEWPORT7
        
    VPDesc.lWidth = g_rcDest.Right - g_rcDest.Left
    VPDesc.lHeight = g_rcDest.Bottom - g_rcDest.Top
    VPDesc.minz = 0#
    VPDesc.maxz = 1#
    
    g_d3dDevice.SetViewport VPDesc
    
    ' Cache the viewport rectangle for use in clearing operations later.
    With g_d3drcViewport(0)
        .X1 = 0: .Y1 = 0
        .X2 = VPDesc.lWidth
        .Y2 = VPDesc.lHeight
    End With
        
    ' Enable ambient lighting
    g_d3dDevice.SetRenderState D3DRENDERSTATE_AMBIENT, g_dx.CreateColorRGBA(1#, 1#, 1#, 1#)
    
    '
    ' Prepare a material
    '
    Dim mtrl As D3DMATERIAL7
   
    mtrl.Ambient.r = 1#: mtrl.Ambient.g = 1#: mtrl.Ambient.b = 0#
    
    ' Commit the material to the device.
    g_d3dDevice.SetMaterial mtrl
    
    '
    ' Set up transformation matrices.
    '
    
    ' The world matrix controls the position and orientation of the polygons
    ' in world space. We'll use it later to spin the triangle.
    Dim matWorld As D3DMATRIX
    
    g_dx.IdentityMatrix matWorld
    g_d3dDevice.SetTransform D3DTRANSFORMSTATE_WORLD, matWorld
    
    ' The view matrix defines the position and orientation of the camera.
    ' Here, we are just moving it back along the z-axis by 15 units.
    Dim matView  As D3DMATRIX
    
    g_dx.IdentityMatrix matView
    
    Call g_dx.ViewMatrix(matView, MakeVector(0, 0, -15), MakeVector(0, 0, 0), _
                         MakeVector(0, 1, 0), 0)
    
    g_d3dDevice.SetTransform D3DTRANSFORMSTATE_VIEW, matView
    
    ' The projection matrix defines how the 3D scene is "projected" onto the
    ' 2D render target (the backbuffer surface). Refer to the docs for more
    ' info about projection matrices.
    Dim matProj As D3DMATRIX
    
    g_dx.IdentityMatrix matProj
    
    Call g_dx.ProjectionMatrix(matProj, 1, 1000, pi / 2)
    g_d3dDevice.SetTransform D3DTRANSFORMSTATE_PROJECTION, matProj
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' Initalize the geometry for the triangle.
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub InitGeometry()

    ' Set up the geometry for the triangle.
    Dim p1 As D3DVECTOR, _
        p2 As D3DVECTOR, _
        p3 As D3DVECTOR, _
        vNormal As D3DVECTOR
   
    ' Set values for three points used to define a triangle.
    p1.x = 0#: p1.y = 5#: p1.z = 0#
    p2.x = 5#: p2.y = -5#: p2.z = 0#
    p3.x = -5#: p3.y = -5#: p3.z = 0#
    
    ' Create a normal vector--shared by the points of the
    ' triangle--that points toward the viewpoint. Note that
    ' we reverse the Z coordinate for the normal of the points
    ' that define the backside of the triangle.
    vNormal.x = 0#: vNormal.y = 0#: vNormal.z = -1#
    
    ' Create the 3 vertices for the front of the triangle.
    g_dx.CreateD3DVertex p1.x, p1.y, p1.z, vNormal.x, vNormal.y, vNormal.z, 0, 0, g_TriangleVert(0)
    g_dx.CreateD3DVertex p2.x, p2.y, p2.z, vNormal.x, vNormal.y, vNormal.z, 0, 0, g_TriangleVert(1)
    g_dx.CreateD3DVertex p3.x, p3.y, p3.z, vNormal.x, vNormal.y, vNormal.z, 0, 0, g_TriangleVert(2)
    
    ' Now do the same for the back of the triangle.
    g_dx.CreateD3DVertex p3.x, p3.y, p3.z, vNormal.x, vNormal.y, -vNormal.z, 0, 0, g_TriangleVert(3)
    g_dx.CreateD3DVertex p2.x, p2.y, p2.z, vNormal.x, vNormal.y, -vNormal.z, 0, 0, g_TriangleVert(4)
    g_dx.CreateD3DVertex p1.x, p1.y, p1.z, vNormal.x, vNormal.y, -vNormal.z, 0, 0, g_TriangleVert(5)
    
End Sub

Private Function MakeVector(a As Double, b As Double, c As Double) As D3DVECTOR
    Dim vecOut As D3DVECTOR
    
    With vecOut
        .x = a
        .y = b
        .z = c
    End With
    
    MakeVector = vecOut
End Function

