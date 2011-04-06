/*////////////////////////////////////////////

GFGAEStudy

Autor	YAMAGUCHI EIKICHI
(@glasses_factory)
Date	2011/04/04

Copyright 2010 glasses factory
http://glasses-factory.net

/*////////////////////////////////////////////

package net.glassesfactory.display
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import org.libspark.betweenas3.BetweenAS3;
	import org.libspark.betweenas3.easing.Back;
	
	public class Image extends Sprite
	{
		/*/////////////////////////////////
		* public variables
		/*/////////////////////////////////
		
		public const MAX_SIZE:int = 180;
		
		
		/*/////////////////////////////////
		* public methods
		/*/////////////////////////////////
		
		//Constractor
		public function Image( bmd:BitmapData )
		{
			_sh = new Shape();
			var fillBmd:BitmapData;
			var wsc:Number = 1;
			var hsc:Number = 1;
			var mt:Matrix = new Matrix();
			if( bmd.width > MAX_SIZE || bmd.height > MAX_SIZE )
			{
				
				if( bmd.width > bmd.height )
				{
					wsc = hsc = MAX_SIZE / bmd.width;
					 
				}
				else
				{
					wsc = hsc = MAX_SIZE / bmd.height;
				}
				mt.scale( wsc, hsc );
			}
			fillBmd = new BitmapData( bmd.width * wsc, bmd.height * hsc );
			fillBmd.draw( bmd, mt );
			_sh.graphics.beginBitmapFill( fillBmd );
			_sh.graphics.drawRect( 0, 0, fillBmd.width, fillBmd.height );
			_sh.graphics.endFill();
			
			_sh.x = -fillBmd.width * .5;
			_sh.y = -fillBmd.height * .5;
			addChild( _sh );
			
			this.graphics.lineStyle( 1, 0xcccccc);
			this.graphics.drawRect( -100, -100, 200, 200 );
			this.graphics.endFill();
			this.visible = false;
			
			
		}
		
		public function disp():void
		{
			this.visible = true;
			BetweenAS3.tween( this, { scaleX:1, scaleY:1, rotation:0 }, { scaleX:0.6, scaleY:0.6, rotation:10 }, 0.4, Back.easeOut ).play();
		}
		
		
		/*/////////////////////////////////
		* private methods
		/*/////////////////////////////////
		
		
		/*/////////////////////////////////
		* private variables
		/*/////////////////////////////////
		
		private var _sh:Shape;
		private var _film:Shape;
	}
}