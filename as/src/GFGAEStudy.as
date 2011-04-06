/*////////////////////////////////////////////

GFGAEStudy

Autor	YAMAGUCHI EIKICHI
(@glasses_factory)
Date	2011/04/03

Copyright 2010 glasses factory
http://glasses-factory.net

/*////////////////////////////////////////////

/**
 * あくまでデータのアップロード、ロードのテストなので表示部分は適当です…
 * ソース汚いのも勘弁… 
 */

package
{
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import net.alumican.as3.ui.justputplay.scrollbars.JPPScrollbar;
	import net.glassesfactory.display.Image;
	import net.glassesfactory.events.GFAMFClientEvent;
	import net.glassesfactory.net.GFAMFClient;
	
	import org.libspark.betweenas3.BetweenAS3;
	import org.libspark.betweenas3.easing.Bounce;
	import org.libspark.betweenas3.easing.Quart;
	
	[SWF(backgroundColor="0xffffff")]
	public class GFGAEStudy extends Sprite
	{
		/*/////////////////////////////////
		* public variables
		/*/////////////////////////////////
		
		//Constractor
		public function GFGAEStudy()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = 60;
			
			_scrollBar = new JPPScrollbar(stage);
			_osType = Capabilities.os.substring( 0, 3 ) == "Mac" ? true : false;
			
			_createDefaultView();
			
			var gateway:String = "http://gf-gaestudy.appspot.com/gateway";
			CONFIG::debug
			{
				gateway = "http://127.0.0.1:8080/gateway"
			}
			
			_amf = new GFAMFClient( gateway );
			CONFIG::debug{ _amf.debug = true; }
			
			//サービスを登録
			_amf.registerService( 'numChildren', 'SimpleImgUtil.getModelNum' );
			_amf.registerService( 'load', 'SimpleImgUtil.load' );
			_amf.registerService( 'upload', 'SimpleImgUtil.upload' );
			_amf.registerService( 'getImgList', 'SimpleImgUtil.getImgList' );
			
			//エラーハンドリング
			_amf.addEventListener( IOErrorEvent.IO_ERROR, _ioErrorHandler );
			_amf.addEventListener( SecurityErrorEvent.SECURITY_ERROR, _securityErrorHandler );
			_amf.addEventListener( AsyncErrorEvent.ASYNC_ERROR, _asyncErrorHandler );
			
			_amf.addEventListener( GFAMFClientEvent.COMPLETE, _initHandler );
			//サーバー側に画像が何枚あるか問い合わせる
			_amf.numChildren();
			
			_column = int(( stage.stageWidth - 180 ) / 220 );
			_row = 50 / _column;
			
			
			
			stage.addEventListener( Event.RESIZE, _stageResizeHandler );
		}
		
		/**
		 * 初期化 
		 * @param e
		 * 
		 */		
		private function _initHandler( e:GFAMFClientEvent ):void
		{
			_amf.removeEventListener( GFAMFClientEvent.COMPLETE, _initHandler );
			
			var imgNum:uint = uint(e.result);
			_status = new Label( this, stage.stageWidth * .5, stage.stageHeight * .5 );
			_status.textField.transform.colorTransform = new ColorTransform( 2, 2, 2 );
			
			//もしなければ NO IMAGE を表示
			if( imgNum < 1 )
			{
				_setStatus("NO IMAGE");
				_createHeader();
			}
			else
			{
				var gridNum:uint = _column * _row;
				var requestNum:uint = ( gridNum > imgNum ) ? imgNum : gridNum; 
				_setStatus("NOW LOADING...");
				_imgVec = new Vector.<BitmapData>( requestNum );
				_byteVec = new Vector.<ByteArray>( requestNum );
				_doBright();
				_amf.addEventListener(GFAMFClientEvent.COMPLETE, _gotImgListdHandler );
				_amf.getImgList( requestNum ) ;
			}
		}
		
		
		/*/////////////////////////////////
		* private methods
		/*/////////////////////////////////
		
		/**
		 * デフォルトのパーツを作成 
		 * 
		 */		
		private function _createDefaultView():void
		{
			_container = new Sprite();
			addChildAt( _container, 0 );
			
			_mask = new Shape();
			_mask.graphics.beginFill( 0 );
			_mask.graphics.drawRect( 0, 0, stage.stageWidth, stage.stageHeight );
			_mask.graphics.endFill();
			addChild( _mask );
			_container.mask = _mask;
			
			_scrollBox = new Sprite();
			_scrollBox.x = stage.stageWidth - 60;
			_scrollBox.y = 45;
			addChild( _scrollBox );
			
			_base = new Sprite();
			_base.graphics.beginFill( 0, 0 );
			_base.graphics.drawRect(0, 0, 60, stage.stageHeight - 45 );
			_base.graphics.endFill();
			_scrollBox.addChild( _base );
			
			_slider = new Sprite();
			_slider.graphics.beginFill( 0, 0.3 );
			_slider.graphics.drawRect( 0, 0, 60, 300 );
			_slider.graphics.endFill();
			_scrollBox.addChild( _slider );
			
			_screen = new Shape();
			_screen.graphics.beginFill( 0 );
			_screen.graphics.drawRect( 0, 0, stage.stageWidth, stage.stageHeight );
			_screen.graphics.endFill();
			addChild( _screen );
			
			_scrollBar.slider = _slider;
			_scrollBar.base = _base;
			_scrollBar.useFlexibleSlider = true;
			_scrollBar.useSmoothScroll = true;
			_scrollBar.upEnabled = false;
			_scrollBar.downEnabled = false;
		}
		
		
		/**
		 * ヘッダーを作成 
		 * 
		 */		
		private function _createHeader():void
		{
			if( _isView ){ return; }
			_header = new Sprite();
			_header.graphics.beginFill( 0 );
			_header.graphics.drawRect( 0, 0, stage.stageWidth, 40 );
			_header.graphics.endFill();
			
			_filePath = new InputText( _header, 10, 10, '', null );
			_filePath.textField.selectable = false;
			_filePath.width = 200;
			_filePath.height = 20;
			
			_fileRefBtn = new PushButton( _header, 220, 10, '', _getFilereferenceHandler );
			_fileRefBtn.label = 'FILE';
			_fileRefBtn.width = 60;
			
			_uploadBtn = new PushButton( _header, 290, 10, '', _doUploadHandler );
			_uploadBtn.label = 'UPLOAD';
			_uploadBtn.width = 60;
			
			addChildAt( _header, 4 );
			_header.alpha = 0;
			BetweenAS3.tween( _header, { alpha:1} , null, 1.2, Quart.easeOut ).play();
			_isView = true;
		}
		
		/**
		 * 写真を表示 
		 * 
		 */		
		private function _dispView():void
		{
			_createHeader();
			removeEventListener( Event.ENTER_FRAME, _brightStatus );
			
			BetweenAS3.parallel(
				BetweenAS3.tween( _status, { alpha:0, _blurFilter:{ blurX:10, blurY:10 }}, null, 1.2, Quart.easeOut ),
				BetweenAS3.tween( _screen, { alpha:0 }, null, 0.4, Quart.easeOut )
			).play();
			
			var index:uint = 0;
			var margX:Number = 100 + ( stage.stageWidth - _column * 220 ) * .5;
			_objVec = new Vector.<Image>();
			for( var i:int = 0; i < _row; ++i )
			{
				for( var j:int = 0; j < _column; ++j )
				{
					if( index > _imgVec.length -1){ break; }
					var bmd:BitmapData = _imgVec[index];
					var sp:Image = new Image( bmd );
					_container.addChild( sp );
					sp.x = j * 220 + margX;
					sp.y = i * 220 + 160;
					_objVec[index] = sp;
					index++;
				}
			}
			_scrollBar.setup(
				_container, "y",
				_container.height + 120,
				_mask.height,
				0,
				0 - ( _container.height + 120 - _mask.height ));
			if( _scrollBar.isUnderFlow )
			{
				_scrollBar.slider.visible = false;
				_scrollBar.useMouseWheel = false;
				_scrollBar.buttonEnabled = false;
			}
			else
			{
				_scrollBar.scrollByAbsolutePixel(0);
			}
			
			_dispTimer = new Timer( 100, index );
			_dispTimer.addEventListener( TimerEvent.TIMER, _doDisp );
			_dispTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _dispTimerCompleteHandler );
			_dispTimer.start();
		}
		
		private function _doDisp( e:TimerEvent ):void
		{
			_objVec[_dispTimer.currentCount-1].disp();
		}
		
		
		private function _dispTimerCompleteHandler( e:TimerEvent ):void
		{
			_dispTimer.removeEventListener(TimerEvent.TIMER, _doDisp );
			_dispTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, _dispTimerCompleteHandler );
			_dispTimer.stop();
			_dispTimer = null;
		}
		
		
		private function _doBright():void
		{
			addEventListener( Event.ENTER_FRAME, _brightStatus );
		}
		
		
		private function _brightStatus( e:Event ):void
		{
			_status.alpha = ( _status.alpha < 1 ) ? 1 : 0.4;
		}
		
		/**
		 * リサイズ 
		 * @param e
		 * 
		 */		
		private function _stageResizeHandler( e:Event ):void
		{
			if( _isView )
			{
				_header.graphics.clear();
				_header.graphics.beginFill( 0, 1 );
				_header.graphics.drawRect( 0, 0, stage.stageWidth, 40 );
				_header.graphics.endFill()
			}
			
			_column = int(( stage.stageWidth - 180 ) / 220 );
			_row = int(50 / _column);
			
			_mask.width = _screen.width = stage.stageWidth;
			_mask.height = _screen.height = stage.stageHeight;
			_status.x = stage.stageWidth * .5 - _status.width * .5;
			_status.y = stage.stageHeight * .5 - _status.height * .5;
			_scrollBox.x = stage.stageWidth - 60;
			_scrollBox.y = 45;
			
			if( _container.numChildren > 0 )
			{
				while(_container.numChildren )
				{
					_container.removeChildAt(0);
				}
				if( _dispTimer )
				{
					_dispTimer.removeEventListener(TimerEvent.TIMER, _doDisp );
					_dispTimer.stop();
					_dispTimer = null;
				}
				_dispView();
			}
		}
		
		
		/*====================================
		* Components Methods
		=====================================*/
		
		private function _getFilereferenceHandler( e:MouseEvent ):void
		{
			_fileRef = new FileReference();
			_fileRef.addEventListener(Event.SELECT, _frSelectHandler );
			_fileRef.addEventListener(Event.COMPLETE, _frLoadCompleteHandler );
			_fileRef.addEventListener(Event.CANCEL, _frCancelHandler );
			_fileRef.addEventListener(Event.OPEN, _frOpenHandler );
			_fileRef.addEventListener(IOErrorEvent.IO_ERROR, _ioErrorHandler );
			_fileRef.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _securityErrorHandler );
			_fileRef.browse([_getImgTypeFilter()]);
		}
		
		/**
		 * NOW Loading...などステータス表示を置き換え 
		 * @param text
		 * 
		 */		
		private function _setStatus( text:String ):void
		{
			_status.text = text;
			_status.draw();
			_status.x = stage.stageWidth * .5 - _status.width * .5;
			_status.y = stage.stageHeight * .5 - _status.height * .5;
		}
		
		
		/*====================================
		* load & upload methods
		=====================================*/
		
		/**
		 * 画像リストを取得後の処理 
		 * @param e
		 * 
		 */		
		private function _gotImgListdHandler( e:GFAMFClientEvent ):void
		{
			_amf.removeEventListener(GFAMFClientEvent.COMPLETE, _gotImgListdHandler );
			var imgs:Array = e.result as Array;
			_cur = 0;
			_loadByteTaskQue(imgs);
		}
		
		
		//え？タスクキューしてないって？そんな野暮なことはいうなよ
		private function _loadByteTaskQue( imgs:Array = null):void
		{
			_amf.addEventListener(GFAMFClientEvent.COMPLETE, function( e:GFAMFClientEvent ):void
			{
				_dec = new Base64Decoder();
				_dec.decode( e.result as String );
				var byte:ByteArray = _dec.flush();
				byte.position = 0;
				byte.uncompress();
				_byteVec[_cur] = byte;
				_cur++;
				_amf.removeEventListener(GFAMFClientEvent.COMPLETE, arguments.callee );
				
				if( _cur >= imgs.length )
				{
					_cur = 0;
					_imgTaskQue();
				}
				else
				{
					_loadByteTaskQue(imgs);
				}
			});
			_amf.load(imgs[_cur]);
		}
		
		
		//え？タスクキューしてないって？そんな野暮なことはい（ｒｙ
		private function _imgTaskQue():void
		{
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function( e:Event ):void
			{
				_imgVec[_cur] = Bitmap( _loader.content ).bitmapData;
				_loader.removeEventListener( Event.COMPLETE, arguments.callee );
				_cur++;
				
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, _ioErrorHandler );
				
				if( _cur >= _byteVec.length )
				{
					_byteVec = null;
					_dispView();
				}
				else
				{
					_imgTaskQue();
				}
			});
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _ioErrorHandler);
			_loader.loadBytes( _byteVec[_cur] );
		}
		
		
		/**
		 * アップロードを実行します 
		 * @param e
		 */		
		private function _doUploadHandler( e:MouseEvent ):void
		{
			if( _bytes == null ){ return; }
			_amf.addEventListener( GFAMFClientEvent.COMPLETE, _uploadCompleteHandler );
			
			BetweenAS3.tween( _screen, { alpha:1 }, { alpha:0.4 }, 0.5, Quart.easeOut ).play();
			_setStatus( "NOW UPLOADING..." );
			_status.filters = [];
			_doBright();
			
			_bytes.compress();
			_bytes.position = 0;
			_enc = new Base64Encoder();
			_enc.encodeBytes( _bytes );
			var encStr:String = _enc.flush();
			
			_amf.upload( encStr, _name);
		}
		
		
		/**
		 * アップロード完了後の処理 
		 * @param e
		 */		
		private function _uploadCompleteHandler( e:GFAMFClientEvent ):void
		{
			_amf.removeEventListener(GFAMFClientEvent.COMPLETE, _uploadCompleteHandler);
			
			while(_container.numChildren )
			{
				_container.removeChildAt(0);
			}
			
			removeEventListener( Event.ENTER_FRAME, _brightStatus );
			_imgVec = null;
			_objVec = null;
			_filePath.text = "";
			removeChild( _status );
			_amf.addEventListener(GFAMFClientEvent.COMPLETE, _initHandler );
			_amf.numChildren();
		}
		
		
		/*====================================
		 * FileRef Handlers
		=====================================*/
		
		private function _frSelectHandler( e:Event ):void
		{
			_fileRef.removeEventListener(Event.SELECT, _frSelectHandler );
			_filePath.text = FileReference(e.target).name;
			_filePath.draw();
			FileReference(e.target).load();
		}
		
		private function _frLoadCompleteHandler( e:Event ):void
		{
			_fileRef.removeEventListener(Event.COMPLETE, _frLoadCompleteHandler );
			if( FileReference(e.target).size >= 800000 )
			{
				_bytes = null;
				return;
			}
			var type:String = FileReference(e.target).type;
			if( _osType )
			{
				if( type != "JPEG" && type != "PNGf" )
				{
					trace("no support image");
					return;
				}
			}
			else
			{
				if( type != ".jpg" && type != ".png" )
				{
					trace("no support image");
					return;
				}
			}
			
			_bytes = FileReference(e.target).data;
			_name = FileReference( e.target ).name;
		}
		
		private function _frCancelHandler( e:Event ):void
		{
			_fileRef.removeEventListener(Event.CANCEL, _frCancelHandler );
			_bytes = null;
		}
		
		private function _frOpenHandler( e:Event ):void
		{
			//open	
		}
		
		private function _getImgTypeFilter():FileFilter
		{
			return new FileFilter("Images (*.jpg, *.jpeg, *.gif, *.png)", "*.jpg;*.jpeg;*.gif;*.png" );
		}
		
		
		/*====================================
		* Error Handlers
		=====================================*/
		
		private function _ioErrorHandler( e:IOErrorEvent ):void
		{
			_bytes = null;
		}
		
		private function _securityErrorHandler( e:SecurityErrorEvent ):void
		{
			//security error
		}
		
		private function _asyncErrorHandler( e:AsyncErrorEvent ):void
		{
			//asyncerror
		}
		
		
		/*/////////////////////////////////
		* private variables
		/*/////////////////////////////////
		
		private var _amf:GFAMFClient;
		private var _brightCnt:uint;
		private var _dispTimer:Timer;
		private var _isView:Boolean = false;
		
		//--- UI ---
		private var _container:Sprite;
		private var _screen:Shape;
		private var _mask:Shape;
		private var _header:Sprite;
		private var _fileRefBtn:PushButton;
		private var _uploadBtn:PushButton;
		private var _filePath:InputText;
		private var _status:Label;
		
		private var _scrollBar:JPPScrollbar;
		private var _scrollBox:Sprite;
		private var _base:Sprite;
		private var _slider:Sprite;
		
		private var _column:uint;
		private var _row:uint;
		
		
		//--- load & upload Img ---
		private var _imgVec:Vector.<BitmapData>;
		private var _byteVec:Vector.<ByteArray>;
		private var _objVec:Vector.<Image>;
		private var _cur:uint;
		private var _enc:Base64Encoder = new Base64Encoder();
		private var _dec:Base64Decoder = new Base64Decoder();
		private var _loader:Loader;
		
		//--- fileref --- 
		private var _osType:Boolean;
		private var _fileRef:FileReference;
		private var _bytes:ByteArray;
		private var _name:String;
	}
}