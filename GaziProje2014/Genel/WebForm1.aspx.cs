using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Genel
{
    public partial class WebForm1 : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            //if (!IsPostBack)
            //{
            //    //string id = Request.QueryString["id"];
            //    //Session.Add("DersIcerikId", id);

            //    if (Request.QueryString["id"] != null)
            //    {
            //        int icerikId = Convert.ToInt32(Request.QueryString["id"]);

            //        GAZIEntities gaziEntities = new GAZIEntities();
            //        DersIcerikler dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
            //        if (dersIcerikler.IcerikTip.Value == 1)
            //        {
            //            pnlIcerikContent.Visible = true;
            //            pnlIcerikFrame.Visible = false;

            //            var genericHtml = new HtmlGenericControl();
            //            genericHtml.InnerHtml = dersIcerikler.IcerikText;
            //            pnlIcerikContent.Controls.Add(genericHtml);
            //        }
            //        else
            //        {
            //            pnlIcerikContent.Visible = false;
            //            pnlIcerikFrame.Visible = true;

            //            string linkAdres = dersIcerikler.IcerikUrl;
            //            LiteralControl literal = new LiteralControl();
            //            literal.Text = "<iframe width=\"100%\" height=\"100%\" src=\"" + linkAdres + "\" frameborder=\"0\" allowfullscreen=\"true\"></iframe>";
            //            pnlIcerikFrame.Controls.Add(literal);
            //        }
            //        //createiframe("//www.youtube.com/embed/A4O0I13pBeM");
            //        //createiframe("/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf");
            //        //createiframe("/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4");
            //    }
            //}

        
            //if (!IsPostBack)
            //{
            //    //string id = Request.QueryString["id"];
            //    //Session.Add("DersIcerikId", id);

            //    if (Request.QueryString["id"] != null)
            //    {
            //        int icerikId = Convert.ToInt32(Request.QueryString["id"]);

            //        GAZIEntities gaziEntities = new GAZIEntities();
            //        DersIcerikler dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
            //        if (dersIcerikler.IcerikTip.Value == 1)
            //        {
            //            //pnlIcerikContent.Visible = true;
            //            //pnlIcerikFrame.Visible = false;

            //            var genericHtml = new HtmlGenericControl();
            //            genericHtml.InnerHtml = dersIcerikler.IcerikText;
            //            pnlIcerikContent.Controls.Add(genericHtml);
            //        }
            //        else
            //        {
            //            //pnlIcerikContent.Visible = false;
            //            //pnlIcerikFrame.Visible = true;

            //            string linkAdres = dersIcerikler.IcerikUrl;
            //            LiteralControl literal = new LiteralControl();
            //            literal.Text = "<iframe width=\"100%\" height=\"100%\" src=\"" + linkAdres + "\" frameborder=\"0\" allowfullscreen=\"true\"></iframe>";
            //            pnlIcerikContent.Controls.Add(literal);
            //        }
            //        //createiframe("//www.youtube.com/embed/A4O0I13pBeM");
            //        //createiframe("/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf");
            //        //createiframe("/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4");
            //    }
            //}
        }
    }
}