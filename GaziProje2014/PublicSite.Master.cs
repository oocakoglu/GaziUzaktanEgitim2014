using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace GaziProje2014
{
    public partial class PublicSite : System.Web.UI.MasterPage
    {

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);

            Random rnd = new Random();
            int sayi = rnd.Next(1, 10);
            string path = "/Style/Background/Back0" + sayi.ToString() +".jpg";

            string backGround = "background: url(" + path + ") no-repeat center center fixed;";
            HtmlGenericControl itemStyle = new HtmlGenericControl("style");
            itemStyle.Attributes.Add("type", "text/css");
            itemStyle.InnerHtml = "html "
                                + "{"
                                + backGround
                                + "-webkit-background-size: cover;"
                                + "-moz-background-size: cover;"
                                + "-o-background-size: cover;"
                                + "background-size: cover;"
                                + "height: 100%;"
                                + "}";


            Page.Header.Controls.Add(itemStyle);
        }

        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}