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
    public partial class VideoIcerik : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (Request.QueryString["id"] != null)
                {
                    int icerikId = Convert.ToInt32(Request.QueryString["id"]);

                    GAZIEntities gaziEntities = new GAZIEntities();
                    //DersIcerikler dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
                    var ders = (from d in gaziEntities.DersIcerikler
                                where d.IcerikId == icerikId
                                select new { d.IcerikUrl, d.IcerikText }).FirstOrDefault();

                    //** Video
                    LiteralControl literal = new LiteralControl();
                    string linkAdres = ders.IcerikUrl;

                    if (linkAdres.IndexOf(".mp4") != -1)
                    {
                        string viodetype = "video/mp4";
                        literal.Text = "<video width=\"100%\" height=\"100%\" controls> "
                            //+ "    <source src=\"/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4\" type=\"video/mp4\"> "
                                     + "    <source src=\"" + linkAdres + "\" type=\"" + viodetype + "\"> "
                                     + "    Tarayıcınız bu videoplayerı desteklemiyor."
                                     + "</video>";
                        pnlvideo.Controls.Add(literal);
                    }
                    else if (linkAdres.IndexOf(".pdf") != -1)
                    {
                        literal.Text = "<object width=\"100%\" height=\"100%\" data=\"" + linkAdres + "\">"
                                     //"<object width=\"100%\" height=\"100%\" data=\"/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf\">"
                                     + "</object>";
                        pnlvideo.Controls.Add(literal);
                    } 


                    //** Açıklama
                    var genericHtml = new HtmlGenericControl();
                    genericHtml.InnerHtml = ders.IcerikText;
                    kareIcerik.Controls.Add(genericHtml);

                }
            }
        }
    }
}