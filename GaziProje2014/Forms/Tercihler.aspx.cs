using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class Tercihler : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }


        protected void grdThemes_NeedDataSource(object source, RadListViewNeedDataSourceEventArgs e)
        {
            using (GAZIDbContext gaziEntities = new GAZIDbContext())
            {
                grdThemes.DataSource = gaziEntities.Temalar.ToList();
                grdThemes.DataKeyNames = new string[]{"TemaId"};        
            }            
        }


        protected void btnTemaUygula_Click(object sender, System.EventArgs e)
        {
            RadButton button = sender as RadButton;
            RadListViewDataItem Item = button.Parent as RadListViewDataItem;
            Label lblTemaPath = ((Label)Item.FindControl("lblTemaPath"));
            string backGround = lblTemaPath.Text;

            GAZIDbContext gaziEntities = new GAZIDbContext();
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
            kullanici.BackGround = backGround;
            gaziEntities.SaveChanges();

            Session.Add("BackGround", backGround);
            Response.Redirect("~/Forms/Tercihler.aspx");
        }


    }
}