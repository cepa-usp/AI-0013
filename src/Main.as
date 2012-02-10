package  
{
	import cepa.utils.ToolTip;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import org.papervision3d.core.geom.Lines3D;
	import org.papervision3d.core.geom.renderables.Line3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.special.Letter3DMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cone;
	import org.papervision3d.objects.primitives.Cylinder;
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.typography.Font3D;
	import org.papervision3d.typography.fonts.HelveticaBold;
	import org.papervision3d.typography.Text3D;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.layer.ViewportLayer;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends BasicView
	{
		/**
		 * Eixos x, y e z.
		 */
		private var eixos:CartesianAxis3D;
		
		/**
		 * Posição do click na tela.
		 */
		private var clickPoint:Point = new Point();
		
		/*
		 * Filtro de conversão para tons de cinza.
		 */
		private const GRAYSCALE_FILTER:ColorMatrixFilter = new ColorMatrixFilter([
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.0000, 0.0000, 0.0000, 1, 0
		]);
		
		private var esfera:Sphere;
		private var planeTeta:DisplayObject3D;
		//private var cone:Cone;
		private var cone:Cylinder;
		private var planeTetaInside:Plane;
		private var lines:Lines3D;
		private var linesCone:Lines3D;
		private var linesConePlane:Lines3D;
		private var pontoIntersecao:Sphere;
		private var interLetter:Text3D;
		private var containerP:DisplayObject3D;
		
		public var distance:Number = 100; 
		private var upVector:Number3D = new Number3D(0, 0, 1);
		
		private var raio:TextField;
		private var teta:TextField;
		private var phi:TextField;
		
		private var balao:CaixaTexto;
		private var tutoSequence:Array = ["Especifique as coordenadas do ponto P nestas caixas de texto (pressione enter para confirmar ou esc para cancelar).", 
										  "Quando as três coordenadas são dadas, obtemos o ponto P definido pela interseção das superfícies associadas a cada coordenada.",
										  "Clique e arraste o mouse sobre a ilustração para modificar o ângulo de visão.",
										  "Use os botões de zoom para ampliar ou reduzir."];
		
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoPhase:Boolean;
		private var pontoP:Point = new Point();
		
		public function Main() 
		{
			super(650, 500, false, false);
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			startRendering();
		}
		
		private function init(e:Event = null):void
		{
			this.scrollRect = new Rectangle(0, 0, 650, 500);
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			eixos = new CartesianAxis3D();
			
			scene.addChild(eixos);
			
			camera.target = null;
			
			raio = coordenadas.raio;
			teta = coordenadas.teta;
			phi = coordenadas.phi;
			
			rotating(null);
			
			botoes.info.addEventListener(MouseEvent.CLICK, showInfo);
			botoes.instructions.addEventListener(MouseEvent.CLICK, showCC);
			botoes.btnInst.addEventListener(MouseEvent.CLICK, openInst);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, resetCamera);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, initRotation);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, viewZoom);
			//zoomBtns.zoomIn.addEventListener(MouseEvent.CLICK, viewZoom);
			//zoomBtns.zoomOut.addEventListener(MouseEvent.CLICK, viewZoom);
			zoomBtns.zoomIn.addEventListener(MouseEvent.MOUSE_DOWN, initZoom);
			zoomBtns.zoomOut.addEventListener(MouseEvent.MOUSE_DOWN, initZoom);
			zoomBtns.zoomIn.mouseChildren = false;
			zoomBtns.zoomOut.mouseChildren = false;
			zoomBtns.zoomIn.buttonMode = true;
			zoomBtns.zoomOut.buttonMode = true;
			zoomBtns.zoomIn.addEventListener(MouseEvent.MOUSE_OVER, over);
			zoomBtns.zoomOut.addEventListener(MouseEvent.MOUSE_OVER, over);
			
			var infoTT:ToolTip = new ToolTip(botoes.info, "Informações", 12, 0.8, 100, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.instructions, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var intTT:ToolTip = new ToolTip(botoes.btnInst, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			
			addChild(infoTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(intTT);
			
			setChildIndex(coordenadas, numChildren - 1);
			setChildIndex(zoomBtns, numChildren - 1);
			setChildIndex(botoes, numChildren - 1);
			setChildIndex(borda, numChildren - 1);
			
			adicionaListenerCampos();
			
			initCampos();
			
			lookAtP();
			
			iniciaTutorial();
			verifyZoomBtns();
		}
		
		private var timerToZoom:Timer = new Timer(200);
		private function initZoom(e:MouseEvent):void 
		{
			if (e.target.name == "zoomIn") {
				if (zoom < 120) zoom +=  5;
				timerToZoom.addEventListener(TimerEvent.TIMER, zooningIn);
			}else {
				if (zoom > 40) zoom -=  5;
				timerToZoom.addEventListener(TimerEvent.TIMER, zooningOut);
			}
			timerToZoom.start();
			stage.addEventListener(MouseEvent.MOUSE_UP, stopZooning);
			
			verifyZoomBtns();
			
			this.camera.zoom = zoom;
		}
		
		private function zooningIn(e:TimerEvent):void 
		{
			if (zoom < 120) {
				zoom +=  5;
				this.camera.zoom = zoom;
			}
			verifyZoomBtns();
		}
		
		private function zooningOut(e:TimerEvent):void 
		{
			if (zoom > 40) {
				zoom -=  5;
				this.camera.zoom = zoom;
			}
			verifyZoomBtns();
		}
		
		private function stopZooning(e:MouseEvent):void 
		{
			timerToZoom.stop();
			timerToZoom.reset();
			timerToZoom.removeEventListener(TimerEvent.TIMER, zooningIn);
			timerToZoom.removeEventListener(TimerEvent.TIMER, zooningOut);
		}
		
		private function verifyZoomBtns():void
		{
			if (zoom == 40) {
				zoomBtns.zoomOut.mouseEnabled = false;
				zoomBtns.zoomOut.filters = [GRAYSCALE_FILTER];
				zoomBtns.zoomOut.alpha = 0.3;
			}
			else {
				zoomBtns.zoomOut.mouseEnabled = true;
				zoomBtns.zoomOut.filters = [];
				zoomBtns.zoomOut.alpha = 1;
			}
			
			if (zoom == 120) {
				zoomBtns.zoomIn.mouseEnabled = false;
				zoomBtns.zoomIn.filters = [GRAYSCALE_FILTER];
				zoomBtns.zoomIn.alpha = 0.3;
			}
			else {
				zoomBtns.zoomIn.mouseEnabled = true;
				zoomBtns.zoomIn.filters = [];
				zoomBtns.zoomIn.alpha = 1;
			}
		}
		
		private function keyUp(e:KeyboardEvent):void 
		{
			if(e.charCode == Keyboard.ESCAPE){
				if (stage.focus == raio) {
					if (!esferaInvisible) raio.text = String(raioNumber);
					else raio.text = "";
					stage.focus = null;
				}else if (stage.focus == teta) {
					if (planeTeta != null) teta.text = String(anguloTeta);
					else teta.text = "";
					stage.focus = null;
				}else if (stage.focus == phi) {
					if (cone != null) phi.text = String(phiNumber);
					else phi.text = "";
					stage.focus = null;
				}
			}
		}
		
		private function over(e:MouseEvent):void 
		{
			var btn:MovieClip = MovieClip(e.target);
			btn.addEventListener(MouseEvent.MOUSE_OUT, out);
			btn.gotoAndStop(2);
		}
		
		private function out(e:MouseEvent):void 
		{
			var btn:MovieClip = MovieClip(e.target);
			btn.removeEventListener(MouseEvent.MOUSE_OUT, out);
			btn.gotoAndStop(1);
		}
		
		private function iniciaTutorial():void 
		{
			tutoPos = 0;
			tutoPhase = true;
			getPCoord();
			
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(coordenadas.x + coordenadas.width, coordenadas.y + coordenadas.height/2),
								pontoP,
								new Point(650/2, 500/2),
								new Point(zoomBtns.x + zoomBtns.width, zoomBtns.y + zoomBtns.height / 2)];
								
				tutoBaloonPos = [[CaixaTexto.LEFT, CaixaTexto.FIRST],
								[CaixaTexto.LEFT, CaixaTexto.FIRST],
								[CaixaTexto.TOP, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.FIRST]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function getPCoord():void
		{
			if(pontoIntersecao != null){
				var bounds:Rectangle = viewport.getChildLayer(pontoIntersecao).getBounds(stage);
				pontoP.x = bounds.x;
				pontoP.y = bounds.y + bounds.height / 2;
				//trace(bounds);
			}
		}
		
		private function closeBalao(e:Event):void 
		{
			//trace("entrou");
			tutoPos++;
			//trace(tutoPos);
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
				tutoPhase = false;
			}else {
				if(tutoPos != 1){
					balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
					balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
				}else {
					if(containerP != null){
						getPCoord();
						if (pontoP.x > 650 / 2) tutoBaloonPos[1][0] = CaixaTexto.RIGHT;
						else tutoBaloonPos[1][0] = CaixaTexto.LEFT;
						
						if (pontoP.y > 500 / 2) tutoBaloonPos[1][1] = CaixaTexto.LAST;
						else tutoBaloonPos[1][1] = CaixaTexto.FIRST;
						
						balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
						balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
					}else {
						closeBalao(null);
					}
				}
			}
		}
		
		private function openInst(e:MouseEvent):void 
		{
			//instScreen.openScreen();
			//setChildIndex(instScreen, numChildren - 1);
			iniciaTutorial();
		}
		
		private function showInfo(e:MouseEvent):void 
		{
			aboutScreen.openScreen();
			setChildIndex(aboutScreen, numChildren - 1);
		}
		
		private function showCC(e:MouseEvent):void 
		{
			infoScreen.openScreen();
			setChildIndex(infoScreen, numChildren - 1);
		}
		
		private var zoom:Number = 40;
		private function viewZoom(e:MouseEvent):void
		{
			if(e.type == MouseEvent.MOUSE_WHEEL){
				if(e.delta > 0)
				{
					if(zoom < 120) zoom +=  5;
				}
				if(e.delta < 0)
				{
					if (zoom > 40) zoom -=  5;
				}
			}else {
				trace(e.target.name);
				if (e.target.name == "zoomIn") {
					if(zoom < 120) zoom +=  5;
				}else {
					if (zoom > 40) zoom -=  5;
				}
			}
			
			verifyZoomBtns();
			
			this.camera.zoom = zoom;
		}
		
		private function initCampos():void
		{
			raio.text = "25";
			teta.text = "60";
			phi.text = "45";
			
			if (cone != null)
			{
				scene.removeChild(cone);
				cone = null;
				linesCone.removeAllLines();
				linesCone = null;
			}
			
			if (planeTeta != null)
			{
				scene.removeChild(planeTeta);
				planeTeta = null;
				lines.removeAllLines();
				lines = null;
			}
			
			if (linesConePlane != null)
			{
				linesConePlane.removeAllLines();
				linesConePlane = null;
			}
			
			if (interLetter != null) 
			{
				containerP.removeChild(interLetter);
				scene.removeChild(containerP);
				interLetter = null;
				containerP = null;
				scene.removeChild(pontoIntersecao);
				pontoIntersecao = null;
			}
			
			drawSphere(Number(raio.text));
			drawPlane(Number(teta.text));
			drawCone(Number(phi.text));
		}
		
		private function adicionaListenerCampos():void
		{
			raio.addEventListener(KeyboardEvent.KEY_UP, changeHandler);
			teta.addEventListener(KeyboardEvent.KEY_UP, changeHandler);
			phi.addEventListener(KeyboardEvent.KEY_UP, changeHandler);
			
			raio.addEventListener(FocusEvent.FOCUS_OUT, changeHandler);
			teta.addEventListener(FocusEvent.FOCUS_OUT, changeHandler);
			phi.addEventListener(FocusEvent.FOCUS_OUT, changeHandler);
			
			raio.addEventListener(FocusEvent.FOCUS_IN, focusInEvent);
			teta.addEventListener(FocusEvent.FOCUS_IN, focusInEvent);
			phi.addEventListener(FocusEvent.FOCUS_IN, focusInEvent);
			
		}
		
		private function focusInEvent(e:FocusEvent):void 
		{
			if (e.target == raio) {
				coordenadas.xBkg.gotoAndStop(2);
			}else if (e.target  == teta) {
				coordenadas.yBkg.gotoAndStop(2);
			}else if (e.target  == phi) {
				coordenadas.zBkg.gotoAndStop(2);
			}
		}
		
		private function changeHandler(e:Event):void 
		{
			if (e is KeyboardEvent) {
				if(KeyboardEvent(e).keyCode == Keyboard.ENTER){
					changePlanes(e.target.name);
					stage.focus = null;
					removeFocus();
				}
			}else {
				if (e.target == raio) {
					if (!esferaInvisible) raio.text = String(raioNumber);
					else raio.text = "";
				}else if (e.target  == teta) {
					if (planeTeta != null) teta.text = String(anguloTeta);
					else teta.text = "";
				}else if (e.target  == phi) {
					if (cone != null) phi.text = String(phiNumber);
					else phi.text = "";
				}
				removeFocus();
			}
		}
		
		private function removeFocus():void 
		{
			coordenadas.xBkg.gotoAndStop(1);
			coordenadas.yBkg.gotoAndStop(1);
			coordenadas.zBkg.gotoAndStop(1);
		}
		
		private var raioNumber:Number;
		private var anguloTeta:Number;
		private var phiNumber:Number;
		private function changePlanes(name:String):void 
		{
			switch (name)
			{
				case "raio":
					if (Number(raio.text) > eixos.maxDist) raio.text = String(eixos.maxDist);
					if (Number(raio.text) < 0) raio.text = "0";
					//if (raio.text == "") raio.text = "0";
					if (raio.text != "") {
						drawSphere(Number(raio.text));
						raioNumber = Number(raio.text);
					}
					else drawSphere(25, true);
					
					if (cone != null) drawCone(Number(phi.text));
					if(planeTeta != null) drawPlane(Number(teta.text));
					break;
				case "teta":
					if (Number(teta.text) > 360) teta.text = "360";
					if (Number(teta.text) < 0) teta.text = "0";
					if (teta.text == "")
					{
						if (planeTeta != null)
						{
							scene.removeChild(planeTeta);
							planeTeta = null;
							lines.removeAllLines();
							lines = null;
						}
						if (linesConePlane != null)
						{
							linesConePlane.removeAllLines();
							linesConePlane = null;
						}
						
						if (interLetter != null) 
						{
							containerP.removeChild(interLetter);
							scene.removeChild(containerP);
							interLetter = null;
							containerP = null;
							scene.removeChild(pontoIntersecao);
							pontoIntersecao = null;
						}
					}
					else drawPlane(Number(teta.text));
					break;
				case "phi":
					if (Number(phi.text) > 180) phi.text = "180";
					if (Number(phi.text) < 0) phi.text = "0";
					if (phi.text == "")
					{
						if (cone != null)
						{
							scene.removeChild(cone);
							cone = null;
							linesCone.removeAllLines();
							linesCone = null;
						}
						if (linesConePlane != null)
						{
							linesConePlane.removeAllLines();
							linesConePlane = null;
						}
						
						if (interLetter != null) 
						{
							containerP.removeChild(interLetter);
							scene.removeChild(containerP);
							interLetter = null;
							containerP = null;
							scene.removeChild(pontoIntersecao);
							pontoIntersecao = null;
						}
					}
					else drawCone(Number(phi.text));
					
					break;
				
				default:
					return;
			}
			verifyNeedOfBallon(name);
		}
		
		private function verifyNeedOfBallon(name:String):void 
		{
			switch(name)
			{
				case "raio":
					if (raio.text == "") {
						if (teta.text == "" && phi.text == "") { //todos nulos
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (teta.text == "") {//x e y nulos
							balao.setText("Quando apenas uma coordenada é dadas, temos a superfície associada a esta coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (phi.text == "") {//x e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else {//x nulo
							balao.setText("Quando apenas duas coordenadas são dadas, obtemos a curva definida pela interseção das superfícies associadas a cada coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}
						balao.setPosition(coordenadas.x + raio.x + raio.width, coordenadas.y + raio.y + raio.height/2);
					}else {
						if(!tutoPhase) balao.visible = false;
					}
					break;
				case "teta":
					if (teta.text == "") {
						if (raio.text == "" && phi.text == "") { //todos nulos
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (raio.text == "") {//x e y nulos
							balao.setText("Quando apenas uma coordenada é dadas, temos a superfície associada a esta coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (phi.text == "") {//y e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else {//y nulo
							balao.setText("Quando apenas duas coordenadas são dadas, obtemos a curva definida pela interseção das superfícies associadas a cada coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}
						balao.setPosition(coordenadas.x + teta.x + teta.width, coordenadas.y + teta.y + teta.height/2);
					}else {
						if(!tutoPhase) balao.visible = false;
					}
					break;
				case "phi":
					if (phi.text == "") {
						if (teta.text == "" && raio.text == "") { //todos nulos
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (teta.text == "") {//z e y nulos
							balao.setText("Quando apenas uma coordenada é dadas, temos a superfície associada a esta coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else if (raio.text == "") {//x e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}else {//z nulo
							balao.setText("Quando apenas duas coordenadas são dadas, obtemos a curva definida pela interseção das superfícies associadas a cada coordenada.", CaixaTexto.LEFT, CaixaTexto.FIRST);
						}
						balao.setPosition(coordenadas.x + phi.x + phi.width, coordenadas.y + phi.y + phi.height/2);
					}else {
						if(!tutoPhase) balao.visible = false;
					}
					break;
				
				default:
					return;
			}
		}
		
		private var esferaInvisible:Boolean = false;
		private function drawSphere(raio:Number, invisible:Boolean = false):void
		{
			trace("desenhando esfera");
			esferaInvisible = invisible;
			var materialSphere:ColorMaterial = new ColorMaterial(0xFF0000, 0.25);
			materialSphere.doubleSided = true;
			
			if (esfera != null) scene.removeChild(esfera);
			
			esfera = new Sphere(materialSphere, raio, 20, 15);
			if (!esferaInvisible) scene.addChild(esfera);
			raioNumber = raio;
			
		}
		
		private function drawPlane(angulo:Number):void
		{
			trace("desenhando plano");
			var material:ColorMaterial = new ColorMaterial(0x0000FF, 0.25);
			material.doubleSided = true;
			
			if (planeTeta != null) 
			{
				planeTeta.removeChild(planeTetaInside);
			}
			else
			{
				planeTeta = new DisplayObject3D();
				scene.addChild(planeTeta);
			}
			
			var raioEsfera:Number;
			if (raio.text != "") raioEsfera = Number(raio.text);
			else raioEsfera = 25;
			
			planeTetaInside = new Plane(material, /*Math.SQRT2*(Number(raio.text) + 2.5)*/(raioEsfera) + 2, 2 * (raioEsfera) + 4, 10, 10);
			
			planeTeta.addChild(planeTetaInside);
			
			//planeTetaInside.x = Math.SQRT2 * (Number(raio.text) + 2.5) / 2;
			planeTetaInside.x = ((raioEsfera) + 2) / 2;
			
			
			if (planeTeta.rotationX != 90) 
			{
				planeTeta.rotationX = 90;
				//planeTeta.x = 15;
				planeTeta.y = 0;
				//planeTeta.z = -15;
			}
			planeTeta.rotationZ = angulo;
			anguloTeta = angulo;
			
			//drawIntersections();
			//drawPlanesIntersection();
			drawRoundIntersection();
			drawIntersectionConePlane();
			
		}
		
		private function drawCone(angulo:Number):void
		{
			trace("desenhando cone");
			var material:ColorMaterial = new ColorMaterial(0x00FF00, 0.25);
			material.doubleSided = true;
			
			if (cone != null)
			{
				scene.removeChild(cone);
			}
			
			var alturaCone:Number;
			var raioCone:Number;
			var raioEsfera:Number;
			
			if (raio.text != "") raioEsfera = Number(raio.text);
			else raioEsfera = 25;
			
			if (angulo <= 45)
			{
				alturaCone = raioEsfera+2;
				raioCone = Math.tan(angulo * (Math.PI / 180)) * alturaCone;
				trace("raio: " + raioCone);
				trace("altura: " + alturaCone);
			}
			else if (angulo <= 135)
			{
				raioCone = raioEsfera + 2;
				alturaCone = raioCone / (Math.tan(Number(phi.text) * Math.PI / 180));
			}
			else
			{
				alturaCone = -(raioEsfera+2);
				raioCone = Math.tan(angulo * (Math.PI / 180)) * alturaCone;
			}
			
			if (raioCone == 0) raioCone = 0.01;
			//cone = new Cone(material, raioCone, alturaCone, 10, 8);
			cone = new Cylinder(material, raioCone, alturaCone, 30, 5, 0, false, false);
			scene.addChild(cone);
			phiNumber = angulo;
			
			if(cone.rotationX != 90) cone.rotationX = 90;
			cone.z = -alturaCone/2;
			
			drawRoundIntersectionCone();
			drawIntersectionConePlane();
		}
		
		/**
		 * @private
		 * Interseção entre planeTeta e a esfera.
		 */
		private function drawRoundIntersection():void
		{
			
			if (lines == null)
			{
				lines = new Lines3D();
				scene.addChild(lines);
				lines.rotationX = 90;
				lines.rotationY = 90;
				
				var portLayerLines:ViewportLayer = viewport.getChildLayer(lines);
				portLayerLines.forceDepth = true;
				portLayerLines.screenDepth = 1;
			}
			else lines.removeAllLines();
			
			if (raio.text == "") return;
			
			var lineMaterial:LineMaterial = new LineMaterial(0x000000);
			
			var linhaIni:Vertex3D;
			var linhaFim:Vertex3D;
			var linha:Line3D;
			
			var maxSeg:int = 120;
			var minSeg:int = 10;
			var raioMax:int = eixos.maxDist;
			
			var nTracos:int = Math.round(minSeg + (maxSeg - minSeg) / raioMax * Number(raio.text)) - 1;
			//if (nTracos % 2 == 0) ++nTracos;
			
			var anguloTraco:Number;
			var anguloTraco2:Number;
			var raioEsfera:Number;
			if (raio.text != "") raioEsfera = Number(raio.text);
			else raioEsfera = 25;
			
			with (Math)
			{
				for (var n:int = 0; n < nTracos; n+= 2)
				{
					
					anguloTraco = PI * n/ (nTracos - 1);
					anguloTraco2 = PI * (n + 1)/ (nTracos - 1);
					
					linhaIni = new Vertex3D(raioEsfera*cos(anguloTraco), raioEsfera*sin(anguloTraco), 0);
					linhaFim = new Vertex3D(raioEsfera*cos(anguloTraco2), raioEsfera*sin(anguloTraco2), 0);
					linha = new Line3D(lines, lineMaterial, 1, linhaIni, linhaFim);
					lines.addLine(linha);
					
				}
			}
			
			lines.rotationZ = Number(teta.text);
		}
		
		/**
		 * @private
		 * Interseção entre o cone e o cilindro.
		 */
		private function drawRoundIntersectionCone():void
		{
			
			if (linesCone == null)
			{
				linesCone = new Lines3D();
				scene.addChild(linesCone);
				
				var portLayerLines:ViewportLayer = viewport.getChildLayer(linesCone);
				portLayerLines.forceDepth = true;
				portLayerLines.screenDepth = 1;
			}
			else linesCone.removeAllLines();
			
			if (raio.text == "") return;
			
			var lineMaterial:LineMaterial = new LineMaterial(0x000000);
			
			var linhaIni:Vertex3D;
			var linhaFim:Vertex3D;
			var linha:Line3D;
			
			var maxSeg:int = 120;
			var minSeg:int = 10;
			var raioMax:int = eixos.maxDist;
			
			var raioEsfera:Number;
			if (raio.text != "") raioEsfera = Number(raio.text);
			else raioEsfera = 25;
			
			var raioPequeno:Number = raioEsfera * Math.sin(Number(phi.text) * (Math.PI / 180));
			var raioZ:Number = raioEsfera * Math.cos(Number(phi.text) * (Math.PI / 180));
			
			var nTracos:int = Math.round(minSeg + (maxSeg - minSeg) / raioMax * raioEsfera);
			if (nTracos % 2 == 0) ++nTracos;
			
			var anguloTraco:Number;
			var anguloTraco2:Number;
			
			
			with (Math)
			{
				for (var n:int = 0; n < nTracos; n+= 2)
				{
					
					anguloTraco = 2 * PI * n/ (nTracos - 1);
					anguloTraco2 = 2 * PI * (n + 1)/ (nTracos - 1);
					
					linhaIni = new Vertex3D(raioPequeno * cos(anguloTraco), raioPequeno * sin(anguloTraco), -raioZ);
					linhaFim = new Vertex3D(raioPequeno * cos(anguloTraco2), raioPequeno * sin(anguloTraco2), -raioZ);
					linha = new Line3D(linesCone, lineMaterial, 1, linhaIni, linhaFim);
					linesCone.addLine(linha);
					
				}
			}
		}
		
		private function criaPonto():void
		{
			if (raio.text == "" || phi.text == "" || teta.text == "") {
				interLetter = null;
				containerP = null;
				scene.removeChild(pontoIntersecao);
				pontoIntersecao = null;
				return;
			}
			
			var raioPequeno:Number = Number(raio.text) * Math.sin(Number(phi.text) * (Math.PI / 180));
			var anguloPlano:Number = Number(teta.text);
			
			var posX:Number = (Math.cos(anguloPlano * (Math.PI / 180))) * raioPequeno;
			var posY:Number = (Math.sin(anguloPlano * (Math.PI / 180))) * raioPequeno;
			var posZ:Number = Number(raio.text) * Math.cos(Number(phi.text) * (Math.PI / 180));
			
			var interMaterial:FlatShadeMaterial = new FlatShadeMaterial(null, 0x000000, 0x000000);
			
			if(pontoIntersecao == null)
			{
				pontoIntersecao = new Sphere(interMaterial, 0.5);
				scene.addChild(pontoIntersecao);
				var portLayerInter:ViewportLayer = viewport.getChildLayer(pontoIntersecao);
				portLayerInter.forceDepth = true;
				portLayerInter.screenDepth = 1;
			}
			
			pontoIntersecao.x = posX;
			pontoIntersecao.y = posY;
			pontoIntersecao.z = -posZ;
			
			if (interLetter == null) 
			{
				var letterMaterial:Letter3DMaterial = new Letter3DMaterial(0x000000);
				letterMaterial.doubleSided = true;
				
				var fonte:Font3D = new HelveticaBold();
				
				var ponto:String = "P";
				
				interLetter = new Text3D(ponto, fonte, letterMaterial);
				interLetter.scale = 0.025;
				interLetter.x = -2.2;
				interLetter.y = -2.2;
				interLetter.rotationY = 180;
				
				containerP = new DisplayObject3D();
				containerP.addChild(interLetter);
				pontoIntersecao.addChild(containerP);
				
				
				containerP.lookAt(camera);
			}
			
			lookAtP();
		}
		
		private function drawIntersectionConePlane():void
		{
			if (linesCone != null && lines != null)
			{
				if (linesConePlane == null)
				{
					linesConePlane = new Lines3D();
					scene.addChild(linesConePlane);
					
					var portLayerLines:ViewportLayer = viewport.getChildLayer(linesConePlane);
					portLayerLines.forceDepth = true;
					portLayerLines.screenDepth = 1;
				}
				else linesConePlane.removeAllLines();
				
				var lineMaterial:LineMaterial = new LineMaterial(0x000000);
				
				var linhaIni:Vertex3D;
				var linhaFim:Vertex3D;
				var linha:Line3D;
				
				
				var angulo = Number(phi.text);
				var alturaCone:Number;
				var raioCone:Number;
				
				var raioEsfera:Number;
				if (raio.text != "") raioEsfera = Number(raio.text);
				else raioEsfera = 25;
				
				if (angulo <= 45 || angulo > 135)
				{
					alturaCone = raioEsfera+2;
					raioCone = Math.tan(angulo * (Math.PI / 180)) * alturaCone;
				}
				else
				{
					raioCone = raioEsfera + 2;
					alturaCone = raioCone / (Math.tan(Number(phi.text) * Math.PI / 180));
				}
				
				var comprimentoTraco:Number = Math.floor(Math.sqrt(alturaCone * alturaCone + raioCone * raioCone));
				
				for (var i:int = 0; i < comprimentoTraco; i = i+2)
				{
					linhaIni = new Vertex3D(i, 0, 0);
					linhaFim = new Vertex3D(i+1, 0, 0);
					linha = new Line3D(linesConePlane, lineMaterial, 1, linhaIni, linhaFim);
					linesConePlane.addLine(linha);
				}
				linesConePlane.rotationY = 90 - angulo;
				linesConePlane.rotationZ = Number(teta.text);
				
				criaPonto();
			}
		}
		
		private function lookAtP():void 
		{
			if(containerP != null) containerP.lookAt(camera, upVector);
			
			eixos.text3dX.lookAt(camera, upVector);
			eixos.text3dY.lookAt(camera, upVector);
			eixos.text3dZ.lookAt(camera, upVector);
			
			eixos.text10x.lookAt(camera, upVector);
			eixos.text10y.lookAt(camera, upVector);
			eixos.text10z.lookAt(camera, upVector);
		}
		
		public var theta2:Number = -2.4188; 
		public var phi2:Number = 10.4537;
		private function initRotation(e:MouseEvent):void 
		{
			if (e.target is TextField || e.target is CaixaTexto) return;
			//{
				clickPoint.x = stage.mouseX;
				clickPoint.y = stage.mouseY;
				stage.addEventListener(Event.ENTER_FRAME, rotating);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopRotating);
			//}
		}
		
		private function rotating(e:Event):void 
		{
			if(e != null){
				var deltaTheta:Number = (stage.mouseX - clickPoint.x) * Math.PI / 180;
				var deltaPhi:Number = (stage.mouseY - clickPoint.y) * Math.PI / 180;
				
				theta2 -= deltaTheta;
				phi2 -= deltaPhi;
				
			
				clickPoint = new Point(stage.mouseX, stage.mouseY);
			}
			
			camera.x = distance * Math.cos(theta2) * Math.sin(phi2);
			camera.y = distance * Math.sin(theta2) * Math.sin(phi2);
			camera.z = distance * Math.cos(phi2);
			
			look();
			lookAtP();
		}
		
		private function stopRotating(e:MouseEvent):void 
		{
			stage.removeEventListener(Event.ENTER_FRAME, rotating);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopRotating);
			//trace(theta2, phi2);
		}
		
		public function look():void {
			if (Math.sin(phi2) < 0) upVector = new Number3D(0, 0, -1);
			else upVector = new Number3D(0, 0, 1);
			
			camera.lookAt(eixos, upVector);
		}
		
		private function resetCamera(e:MouseEvent):void
		{
			theta2 = -2.4188;
			phi2 = 10.4537;
			
			zoom = 40;
			this.camera.zoom = zoom;
			
			rotating(null);
			
			initCampos();
			
			lookAtP();
			balao.visible = false;
			tutoPhase = false;
			verifyZoomBtns();
		}
		
	}
}