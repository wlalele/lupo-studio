package com.dehats.lupo.view
{
	import mx.controls.RichTextEditor;
	
	public class TranslationTextEditor extends RichTextEditor
	{
		public function TranslationTextEditor()
		{
			super();
		}
		
		override public function get text():String
		{
			return super.htmlText;
		}
		
		override public function set text(value:String):void
		{
			super.htmlText = value;
		}	
	}
}