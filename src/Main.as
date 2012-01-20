package  
{
	import cepa.utils.ToolTip;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
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
		
		private var balao:CaixaTexto;
		
		public function Main() 
		{
			super(650, 500, false, true);
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
			
			rotating(null);
			
			info.addEventListener(MouseEvent.CLICK, showInfo);
			instructions.addEventListener(MouseEvent.CLICK, showCC);
			btnInst.addEventListener(MouseEvent.CLICK, openInst);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, initRotation);
			resetButton.addEventListener(MouseEvent.CLICK, resetCamera);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, viewZoom);
			zoomIn.addEventListener(MouseEvent.CLICK, viewZoom);
			zoomOut.addEventListener(MouseEvent.CLICK, viewZoom);
			setChildIndex(zoomIn, numChildren - 1);
			setChildIndex(zoomOut, numChildren - 1);
			
			var infoTT:ToolTip = new ToolTip(info, "Informações", 12, 0.8, 100, 0.6, 0.6);
			var instTT:ToolTip = new ToolTip(instructions, "Instruções", 12, 0.8, 100, 0.6, 0.6);
			var resetTT:ToolTip = new ToolTip(resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.6);
			
			addChild(infoTT);
			addChild(instTT);
			addChild(resetTT);
			
			setChildIndex(raio, numChildren - 1);
			setChildIndex(teta, numChildren - 1);
			setChildIndex(phi, numChildren - 1);
			
			adicionaListenerCampos();
			
			initCampos();
			
			lookAtP();
			
			balao = new CaixaTexto();
			addChild(balao);
			balao.visible = false;
		}
		
		private function openInst(e:MouseEvent):void 
		{
			instScreen.openScreen();
			setChildIndex(instScreen, numChildren - 1);
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
				if (e.target is ZoomIn) {
					if(zoom < 120) zoom +=  5;
				}else {
					if (zoom > 40) zoom -=  5;
				}
			}
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
		}
		
		private function changeHandler(e:Event):void 
		{
			if(e is KeyboardEvent){
				if(KeyboardEvent(e).keyCode == Keyboard.ENTER){
					changePlanes(e.target.name);
				}
			}else {
				changePlanes(e.target.name);
			}
		}
		
		private function changePlanes(name:String):void 
		{
			switch (name)
			{
				case "raio":
					if (Number(raio.text) > eixos.maxDist) raio.text = String(eixos.maxDist);
					if (Number(raio.text) < 0) raio.text = "0";
					//if (raio.text == "") raio.text = "0";
					if (raio.text != "") drawSphere(Number(raio.text));
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
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.");
						}else if (teta.text == "") {//x e y nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else if (phi.text == "") {//x e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else {//x nulo
							balao.setText("Com esse parâmetro nulo existem apenas 2 planos, sendo que a interseção entre eles forma uma reta.");
						}
						balao.x = raio.x + raio.width + 20;
						balao.y = raio.y;					
					}else {
						balao.visible = false;
					}
					break;
				case "teta":
					if (teta.text == "") {
						if (raio.text == "" && phi.text == "") { //todos nulos
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.");
						}else if (raio.text == "") {//x e y nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else if (phi.text == "") {//y e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else {//y nulo
							balao.setText("Com esse parâmetro nulo existem apenas 2 planos, sendo que a interseção entre eles forma uma reta.");
						}
						balao.x = teta.x + teta.width + 20;
						balao.y = teta.y;					
					}else {
						balao.visible = false;
					}
					break;
				case "phi":
					if (phi.text == "") {
						if (teta.text == "" && raio.text == "") { //todos nulos
							balao.setText("Com todos os parâmetros nulos não existem planos nem interseções.");
						}else if (teta.text == "") {//z e y nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else if (raio.text == "") {//x e z nulos
							balao.setText("Com dois parâmetros nulos existe apenas 1 plano sem interseções.");
						}else {//z nulo
							balao.setText("Com esse parâmetro nulo existem apenas 2 planos, sendo que a interseção entre eles forma uma reta.");
						}
						balao.x = phi.x + phi.width + 20;
						balao.y = phi.y;					
					}else {
						balao.visible = false;
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
			if(!esferaInvisible) scene.addChild(esfera);
			
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
			planeTeta.rotationZ = Number(teta.text);
			
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
				interLetter.scale = 0.02;
				interLetter.x = -1.2;
				interLetter.y = 1.2;
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
				
				theta2 += deltaTheta;
				phi2 += deltaPhi;
				
			
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
		}
		
	}
}