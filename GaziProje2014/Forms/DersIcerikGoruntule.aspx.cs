using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class DersIcerikGoruntule : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            if (!IsPostBack)
            {

                if (Session["DersIcerikId"] != null)
                {
                    int icerikId = Convert.ToInt32(Session["DersIcerikId"]);

                    GAZIEntities gaziEntities = new GAZIEntities();
                    DersIcerikler dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
                    if (dersIcerikler.IcerikTip.Value == 1)
                    {
                        pnlIcerikContent.Visible = true;
                        pnlIcerikFrame.Visible = false;

                        var genericHtml = new HtmlGenericControl();
                        genericHtml.InnerHtml = dersIcerikler.IcerikText;
                        pnlIcerikContent.Controls.Add(genericHtml);
                    }
                    else
                    {
                        pnlIcerikContent.Visible = false;
                        pnlIcerikFrame.Visible = true;

                        string linkAdres = dersIcerikler.IcerikUrl;
                        LiteralControl literal = new LiteralControl();
                        literal.Text = "<iframe width=\"100%\" height=\"100%\" src=\"" + linkAdres + "\" frameborder=\"0\" allowfullscreen=\"true\"></iframe>";
                        pnlIcerikFrame.Controls.Add(literal);
                    }
                    Session["DersIcerikId"] = dersIcerikler.OgretmenDersId.ToString();
                    //createiframe("//www.youtube.com/embed/A4O0I13pBeM");
                    //createiframe("/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf");
                    //createiframe("/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4");
                }
            }
        }

        protected void btnGeri_Click(object sender, EventArgs e)
        {
            if (Session["SayfaGeri"] != null)
            {
                string SayfaUrl = Session["SayfaGeri"].ToString();
                Session.Remove("SayfaGeri");
                Response.Redirect(SayfaUrl);
            }
            else
            {
                Session.Remove("DersIcerikId");
                Response.Redirect("~/Forms/OgrenciDersKonular.aspx");
            }
        }




    }
}