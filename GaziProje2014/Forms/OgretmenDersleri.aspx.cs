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
    public partial class OgretmenDersleri : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            if (!IsPostBack)
            {
                grdSecilenDerslerBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdSecilenDerslerBind();
        }

        protected void btnDersleriSil_Click(object sender, EventArgs e)
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIDbContext gaziEntities = new GAZIDbContext();
            foreach (GridDataItem item in grdSecilenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgretmenOnay");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    gaziEntities.OgretmenDersler.Remove(ogretmenDersler);
                }
            }
            gaziEntities.SaveChanges();
            grdSecilenDerslerBind();
        }

        protected void btnDersleriOnayla_Click(object sender, EventArgs e)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();

            foreach (GridDataItem item in grdSecilenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgretmenOnay");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    ogretmenDersler.OgretmenOnayi = true;
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdSecilenDerslerBind();
        }
        //
        protected void btnDersIcerik_Click(object sender, EventArgs e)
        {
            if (grdSecilenDersler.SelectedItems.Count > 0)
            {
                string ogretmenDersId = grdSecilenDersler.SelectedValues["OgretmenDersId"].ToString();
                bool? yoneticiOnay = (bool?)grdSecilenDersler.SelectedValues["UstOnay"];

                if (yoneticiOnay == true)
                {
                    Session.Add("OgretmenDersId", ogretmenDersId);
                    Response.Redirect("~/Forms/DersIcerikYoneticisi.aspx");
                }
                else
                {
                    ShowMesaj("Yönetici Tarafından onay verilmeyen derslerin içeriği görüntülenemez");
                }
            }
        }

        private void grdSecilenDerslerBind()
        {

            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIDbContext gaziEntities = new GAZIDbContext();
            var secilenDersler = (from od in gaziEntities.OgretmenDersler
                                  join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                  where od.OgretmenId == kullaniciId
                                  select new { od.OgretmenDersId, od.OgretmenId, od.OgretmenOnayi, od.UstOnay, d.DersAdi, d.DersAciklama }).OrderBy(q => q.DersAdi).Take(100).ToList();
            grdSecilenDersler.DataSource = secilenDersler;
            grdSecilenDersler.DataBind();
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }
    }
}