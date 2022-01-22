using GaziProje2014.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class Dersler : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void grdDersler_NeedDataSource(object source, GridNeedDataSourceEventArgs e)
        {
            using (GAZIDbContext gaziEntities = new GAZIDbContext())
            {
                grdDersler.DataSource = gaziEntities.Dersler.ToList();
            }
        }


        protected void grdDersler_ItemCommand(object sender, GridCommandEventArgs e)
        {
            GridItem item = e.Item;
            RadTextBox txtDersAdi = item.FindControl("txtDersAdi") as RadTextBox;
            RadTextBox txtDersAciklama = item.FindControl("txtDersAciklama") as RadTextBox;
            if (e.CommandName.Equals("PerformInsert"))
            {
                using (GAZIDbContext db = new GAZIDbContext())
                {
                    Data.Models.Dersler ders = new Data.Models.Dersler();
                    ders.DersAdi = txtDersAdi.Text;
                    ders.DersAciklama = txtDersAciklama.Text;    
                    db.Dersler.Add(ders);
                    db.SaveChanges();
                }
            }
            else if (e.CommandName.Equals("Update"))
            {
                HtmlInputHidden dersIdInput = item.FindControl("dersId") as HtmlInputHidden;
                int dersId = Convert.ToInt32(dersIdInput.Value);
                using (GAZIDbContext db = new GAZIDbContext())
                {
                    Data.Models.Dersler ders = db.Dersler.Where(q => q.DersId == dersId).FirstOrDefault();
                    ders.DersAdi = txtDersAdi.Text;
                    ders.DersAciklama = txtDersAciklama.Text;
                    db.SaveChanges();
                }
            }
        }


    }
}