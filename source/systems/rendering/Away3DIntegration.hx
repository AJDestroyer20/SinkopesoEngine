package systems.rendering;

#if FEATURE_AWAY3D
import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.primitives.CubeGeometry;
import away3d.primitives.SphereGeometry;
import away3d.primitives.CylinderGeometry;
import openfl.display.Sprite;
#end

class Away3DIntegration
{
	#if FEATURE_AWAY3D
	public var view3D:View3D;
	public var container:Sprite;
	
	public var models:Array<Mesh> = [];
	
	public function new(width:Int, height:Int)
	{
		container = new Sprite();
		
		view3D = new View3D();
		view3D.width = width;
		view3D.height = height;
		view3D.antiAlias = 4;
		
		container.addChild(view3D);
	}
	
	public function addCube(size:Float = 100, color:Int = 0xFF0000):Mesh
	{
		var geometry:CubeGeometry = new CubeGeometry(size, size, size);
		var material:ColorMaterial = new ColorMaterial(color);
		
		var mesh:Mesh = new Mesh(geometry, material);
		view3D.scene.addChild(mesh);
		
		models.push(mesh);
		
		return mesh;
	}
	
	public function addSphere(radius:Float = 50, color:Int = 0x00FF00):Mesh
	{
		var geometry:SphereGeometry = new SphereGeometry(radius);
		var material:ColorMaterial = new ColorMaterial(color);
		
		var mesh:Mesh = new Mesh(geometry, material);
		view3D.scene.addChild(mesh);
		
		models.push(mesh);
		
		return mesh;
	}
	
	public function addCylinder(radius:Float = 25, height:Float = 100, color:Int = 0x0000FF):Mesh
	{
		var geometry:CylinderGeometry = new CylinderGeometry(radius, radius, height);
		var material:ColorMaterial = new ColorMaterial(color);
		
		var mesh:Mesh = new Mesh(geometry, material);
		view3D.scene.addChild(mesh);
		
		models.push(mesh);
		
		return mesh;
	}
	
	public function update():Void
	{
		if (view3D != null)
		{
			view3D.render();
		}
	}
	
	public function setCamera(x:Float, y:Float, z:Float):Void
	{
		view3D.camera.x = x;
		view3D.camera.y = y;
		view3D.camera.z = z;
	}
	
	public function lookAt(x:Float, y:Float, z:Float):Void
	{
		view3D.camera.lookAt(new away3d.geom.Vector3D(x, y, z));
	}
	
	public function dispose():Void
	{
		for (model in models)
		{
			view3D.scene.removeChild(model);
			model.dispose();
		}
		
		models = [];
		
		if (view3D != null)
		{
			view3D.dispose();
			view3D = null;
		}
	}
	
	#else
	
	public function new(width:Int, height:Int) 
	{
		trace('Away3D not available - FEATURE_AWAY3D not defined');
	}
	
	public function addCube(size:Float = 100, color:Int = 0xFF0000):Dynamic { return null; }
	public function addSphere(radius:Float = 50, color:Int = 0x00FF00):Dynamic { return null; }
	public function addCylinder(radius:Float = 25, height:Float = 100, color:Int = 0x0000FF):Dynamic { return null; }
	public function update():Void {}
	public function setCamera(x:Float, y:Float, z:Float):Void {}
	public function lookAt(x:Float, y:Float, z:Float):Void {}
	public function dispose():Void {}
	
	#end
}
