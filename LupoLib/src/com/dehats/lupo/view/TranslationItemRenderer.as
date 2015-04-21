package com.dehats.lupo.view
{
	import mx.controls.dataGridClasses.DataGridItemRenderer;

	public class TranslationItemRenderer extends DataGridItemRenderer
	{
		public function TranslationItemRenderer()
		{
			super();
		}
		
		override public function get text():String
		{
			return super.htmlText;	
		}
				
		override public function set text(value:String):void
		{
			super.htmlText = (value !== null) ? value : "Not translated";
		}
	}
}