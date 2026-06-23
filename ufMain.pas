unit ufMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Skia,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Skia, FMX.Colors,
  FMX.ListBox, FMX.Ani;

type
  TfrmMain = class(TForm)
    SkPaintBox1: TSkPaintBox;
    Layout1: TLayout;
    Label1: TLabel;
    btnRun: TButton;
    btnStop: TButton;
    Timer1: TTimer;
    ColorComboBox1: TColorComboBox;
    cbMode: TComboBox;
    chkAxes: TCheckBox;
    chkPerspective: TCheckBox;
    Layout2: TLayout;
    lblZoom: TLabel;
    Layout3: TLayout;
    lblSigmaTitle: TLabel;
    lblSigmaValue: TLabel;
    tbSigma: TTrackBar;
    lblRhoTitle: TLabel;
    lblRhoValue: TLabel;
    tbRho: TTrackBar;
    lblBetaTitle: TLabel;
    lblBetaValue: TLabel;
    tbBeta: TTrackBar;
    btnResetParams: TButton;
    procedure SkPaintBox1Draw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
    procedure Timer1Timer(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure ColorComboBox1Change(Sender: TObject);
    procedure cbModeChange(Sender: TObject);
    procedure chkAxesChange(Sender: TObject);
    procedure chkPerspectiveChange(Sender: TObject);
    procedure SkPaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SkPaintBox1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Single);
    procedure SkPaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SkPaintBox1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure tbParamChange(Sender: TObject);
    procedure btnResetParamsClick(Sender: TObject);
  private
    FX, FY, FZ: Double;
    FPoints: TArray<TPoint3D>;
    FCount: Integer;
    FPlotColor: TAlphaColor;
    FYaw, FPitch: Single;
    FZoom: Single;
    FSigma, FRho, FBeta: Double;
    FDragging: Boolean;
    FLastMouse: TPointF;
    function Is3D: Boolean;
    function Project2D(const P: TPoint3D; const ADest: TRectF): TPointF;
    function Project3D(const P: TPoint3D; const ADest: TRectF): TPointF;
    function ProjectAuto(const P: TPoint3D; const ADest: TRectF): TPointF;
    procedure DrawAxes(const ACanvas: ISkCanvas; const ADest: TRectF);
    procedure ResetSimulation;
    procedure StepLorenz(ASteps: Integer);
    procedure UpdateZoomLabel;
  public
    procedure AfterConstruction; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

const
  DT    = 0.005;
  STEPS_PER_TICK = 25;
  MAX_POINTS = 200000;

  // 2D world bounds for the (x, z) projection.
  WORLD_MIN_X = -25.0;
  WORLD_MAX_X =  25.0;
  WORLD_MIN_Z =  -5.0;
  WORLD_MAX_Z =  55.0;

  // 3D view: centre of the attractor and orthographic scale (units → pixels uses Min(w,h) / VIEW_EXTENT).
  CENTRE_X = 0.0;
  CENTRE_Y = 0.0;
  CENTRE_Z = 25.0;
  VIEW_EXTENT = 60.0;
  CAMERA_DIST = 80.0;  // perspective focal distance in world units

procedure TfrmMain.AfterConstruction;
begin
  inherited;
  FYaw   := 0.7;   // ~40°
  FPitch := 0.35;  // ~20°
  FZoom  := 1.0;
  FSigma := tbSigma.Value;
  FRho   := tbRho.Value;
  FBeta  := tbBeta.Value;
  UpdateZoomLabel;
end;

procedure TfrmMain.UpdateZoomLabel;
begin
  lblZoom.Text := Format('Zoom: %.0f%%', [FZoom * 100.0]);
end;

procedure TfrmMain.btnResetParamsClick(Sender: TObject);
begin
  tbSigma.Value := 10.0;
  tbRho.Value   := 28.0;
  tbBeta.Value  := 8.0 / 3.0;
  // tbParamChange fires from each assignment and refreshes fields + labels.
end;

procedure TfrmMain.tbParamChange(Sender: TObject);
begin
  FSigma := tbSigma.Value;
  FRho   := tbRho.Value;
  FBeta  := tbBeta.Value;
  lblSigmaValue.Text := Format('%.2f', [FSigma]);
  lblRhoValue.Text   := Format('%.2f', [FRho]);
  lblBetaValue.Text  := Format('%.2f', [FBeta]);
end;

procedure TfrmMain.ResetSimulation;
begin
  FX := 1.0;
  FY := 1.0;
  FZ := 1.0;
  SetLength(FPoints, 4096);
  FCount := 0;
  if FPlotColor = 0 then
    FPlotColor := ColorComboBox1.Color;
end;

procedure TfrmMain.ColorComboBox1Change(Sender: TObject);
begin
  FPlotColor := ColorComboBox1.Color;
  SkPaintBox1.Redraw;
end;

procedure TfrmMain.cbModeChange(Sender: TObject);
begin
  SkPaintBox1.Redraw;
end;

procedure TfrmMain.chkAxesChange(Sender: TObject);
begin
  SkPaintBox1.Redraw;
end;

procedure TfrmMain.chkPerspectiveChange(Sender: TObject);
begin
  SkPaintBox1.Redraw;
end;

function TfrmMain.Is3D: Boolean;
begin
  Result := cbMode.ItemIndex = 1;
end;

procedure TfrmMain.StepLorenz(ASteps: Integer);
var
  i: Integer;
  dx, dy, dz: Double;
begin
  for i := 0 to ASteps - 1 do
  begin
    dx := FSigma * (FY - FX);
    dy := FX * (FRho - FZ) - FY;
    dz := FX * FY - FBeta * FZ;
    FX := FX + DT * dx;
    FY := FY + DT * dy;
    FZ := FZ + DT * dz;

    if FCount >= MAX_POINTS then
      Continue;
    if FCount >= Length(FPoints) then
      SetLength(FPoints, Length(FPoints) * 2);
    FPoints[FCount] := Point3D(FX, FY, FZ);
    Inc(FCount);
  end;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  ResetSimulation;
  SkPaintBox1.Redraw;
  Timer1.Enabled := True;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  Timer1.Enabled := False;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  StepLorenz(STEPS_PER_TICK);
  SkPaintBox1.Redraw;
end;

procedure TfrmMain.SkPaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not Is3D then Exit;
  FDragging := True;
  FLastMouse := PointF(X, Y);
end;

procedure TfrmMain.SkPaintBox1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
const
  ROT_SPEED = 0.01;
begin
  if not FDragging then Exit;
  FYaw   := FYaw   + (X - FLastMouse.X) * ROT_SPEED;
  FPitch := FPitch + (Y - FLastMouse.Y) * ROT_SPEED;
  FPitch := EnsureRange(FPitch, -Pi / 2, Pi / 2);
  FLastMouse := PointF(X, Y);
  SkPaintBox1.Redraw;
end;

procedure TfrmMain.SkPaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FDragging := False;
end;

procedure TfrmMain.SkPaintBox1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
const
  ZOOM_STEP = 1.15;
begin
  if WheelDelta > 0 then
    FZoom := FZoom * ZOOM_STEP
  else if WheelDelta < 0 then
    FZoom := FZoom / ZOOM_STEP;
  FZoom := EnsureRange(FZoom, 0.1, 20.0);
  UpdateZoomLabel;
  SkPaintBox1.Redraw;
  Handled := True;
end;

function TfrmMain.Project2D(const P: TPoint3D; const ADest: TRectF): TPointF;
var
  sx, sy: Single;
begin
  sx := ADest.Width  / (WORLD_MAX_X - WORLD_MIN_X);
  sy := ADest.Height / (WORLD_MAX_Z - WORLD_MIN_Z);
  Result.X := ADest.Left   + (P.X - WORLD_MIN_X) * sx;
  Result.Y := ADest.Bottom - (P.Z - WORLD_MIN_Z) * sy;
end;

function TfrmMain.Project3D(const P: TPoint3D; const ADest: TRectF): TPointF;
var
  tx, ty, tz, rx, ry, rz, ry2, rz2: Single;
  cy_, sy_, cp_, sp_, scale, persp, denom: Single;
  centre: TPointF;
begin
  tx := P.X - CENTRE_X;
  ty := P.Y - CENTRE_Y;
  tz := P.Z - CENTRE_Z;

  // Yaw around the world Y (vertical-ish) axis.
  cy_ := Cos(FYaw); sy_ := Sin(FYaw);
  rx :=  cy_ * tx + sy_ * tz;
  rz := -sy_ * tx + cy_ * tz;
  ry := ty;

  // Pitch around the camera X axis.
  cp_ := Cos(FPitch); sp_ := Sin(FPitch);
  ry2 := cp_ * ry - sp_ * rz;
  rz2 := sp_ * ry + cp_ * rz;

  scale := Min(ADest.Width, ADest.Height) / VIEW_EXTENT;

  if chkPerspective.IsChecked then
  begin
    denom := CAMERA_DIST - rz2;  // positive rz2 = closer to camera
    if denom < 1.0 then denom := 1.0;  // avoid divide-by-tiny / sign flip
    persp := CAMERA_DIST / denom;
  end
  else
    persp := 1.0;

  centre := ADest.CenterPoint;
  Result.X := centre.X + rx  * scale * persp;
  Result.Y := centre.Y - ry2 * scale * persp;  // flip Y for screen
end;

function TfrmMain.ProjectAuto(const P: TPoint3D; const ADest: TRectF): TPointF;
var
  centre: TPointF;
begin
  if Is3D then
    Result := Project3D(P, ADest)
  else
    Result := Project2D(P, ADest);
  if FZoom <> 1.0 then
  begin
    centre := ADest.CenterPoint;
    Result.X := centre.X + (Result.X - centre.X) * FZoom;
    Result.Y := centre.Y + (Result.Y - centre.Y) * FZoom;
  end;
end;

procedure TfrmMain.DrawAxes(const ACanvas: ISkCanvas; const ADest: TRectF);
var
  LineP, TextP: ISkPaint;
  LFont: ISkFont;

  procedure Axis(const A, B: TPoint3D; AColor: TAlphaColor; const ALabel: string);
  var
    p0, p1: TPointF;
  begin
    p0 := ProjectAuto(A, ADest);
    p1 := ProjectAuto(B, ADest);
    LineP.Color := AColor;
    ACanvas.DrawLine(p0.X, p0.Y, p1.X, p1.Y, LineP);
    TextP.Color := AColor;
    ACanvas.DrawSimpleText(ALabel, p1.X + 4, p1.Y - 4, LFont, TextP);
  end;

begin
  if not chkAxes.IsChecked then
    Exit;

  LineP := TSkPaint.Create(TSkPaintStyle.Stroke);
  LineP.AntiAlias := True;
  LineP.StrokeWidth := 1.5;

  TextP := TSkPaint.Create;
  TextP.AntiAlias := True;

  LFont := TSkFont.Create(nil, 13);

  if Is3D then
  begin
    Axis(Point3D(0, 0, 0), Point3D(30, 0, 0), $FFFF6464, 'X');
    Axis(Point3D(0, 0, 0), Point3D(0, 30, 0), $FF64FF64, 'Y');
    Axis(Point3D(0, 0, 0), Point3D(0, 0, 30), $FF6496FF, 'Z');
  end
  else
  begin
    Axis(Point3D(WORLD_MIN_X, 0, 0), Point3D(WORLD_MAX_X, 0, 0), $FFFF6464, 'X');
    Axis(Point3D(0, 0, WORLD_MIN_Z), Point3D(0, 0, WORLD_MAX_Z), $FF6496FF, 'Z');
  end;
end;

procedure TfrmMain.SkPaintBox1Draw(ASender: TObject; const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
  LBuilder: ISkPathBuilder;
  LPath: ISkPath;
  i: Integer;
  pt: TPointF;
begin
  LPaint := TSkPaint.Create;
  LPaint.Color := $FF101018;
  ACanvas.DrawRect(ADest, LPaint);

  DrawAxes(ACanvas, ADest);

  if FCount < 2 then
    Exit;

  LBuilder := TSkPathBuilder.Create;
  pt := ProjectAuto(FPoints[0], ADest);
  LBuilder.MoveTo(pt.X, pt.Y);
  for i := 1 to FCount - 1 do
  begin
    pt := ProjectAuto(FPoints[i], ADest);
    LBuilder.LineTo(pt.X, pt.Y);
  end;
  LPath := LBuilder.Detach;

  LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
  LPaint.AntiAlias := True;
  LPaint.StrokeWidth := 1.0;
  LPaint.Color := FPlotColor;
  ACanvas.DrawPath(LPath, LPaint);
end;

end.
