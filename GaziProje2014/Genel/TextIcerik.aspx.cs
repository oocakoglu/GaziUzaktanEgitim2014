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
    public partial class TextIcerik : System.Web.UI.Page
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
                    string Icerik = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).Select(q => q.IcerikText).SingleOrDefault();


                    var genericHtml = new HtmlGenericControl();
                    genericHtml.InnerHtml = Icerik;
                    pnlIcerikContent.Controls.Add(genericHtml);                 
                }
            }
        }
    }
}