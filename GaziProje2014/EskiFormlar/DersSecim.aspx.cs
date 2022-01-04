using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class DersSecim : System.Web.UI.Page
    { 

        protected void Page_Load(object sender, EventArgs e)
        {
            Session.Add("KullaniciId", 1);
            GAZIEntities gaziEntities = new GAZIEntities();
            if (!IsPostBack)
            {
                var tumdersler = (from d in gaziEntities.Dersler
                                  select d).Where(q => q.DersDurum == true).OrderBy(x => x.DersAdi).ToList();

                grdTumDersler.DataSource = tumdersler;
                grdTumDersler.DataBind();

                //if (RadTabStrip1.SelectedIndex == 1)
                SecilenDerslerBind();
            }
        }

        private void SecilenDerslerBind()
        {

            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();
            var secilenDersler = (from od in gaziEntities.OgretmenDersler
                                  join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                  where od.OgretmenId == kullaniciId
                                  select new { od.OgretmenDersId, od.OgretmenId, od.OgretmenOnayi, od.UstOnay, d.DersAdi, d.DersAciklama }).OrderBy(q => q.DersAdi).Take(100).ToList();
            grdSecilenDersler.DataSource = secilenDersler;
            grdSecilenDersler.DataBind();
        }
        
        protected void btnDersEkle_Click(object sender, EventArgs e)
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdTumDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["TemplateColumn"].FindControl("CheckBox1");
                if (chk.Checked)
                {
                    int dersId = Convert.ToInt32(item["DersId"].Text);
                    int KayitSayi = gaziEntities.OgretmenDersler.Where(x => x.OgretmenId == kullaniciId && x.DersId == dersId).Count();
                    if (KayitSayi == 0)
                    {
                        OgretmenDersler kullaniciDersler = new OgretmenDersler();
                        kullaniciDersler.DersId = dersId;
                        kullaniciDersler.OgretmenId = kullaniciId;
                        gaziEntities.OgretmenDersler.Add(kullaniciDersler);
                    }
                }
            }
            gaziEntities.SaveChanges();

            RadTabStrip1.SelectedIndex = 1;
            RadPageView2.Selected = true;
            SecilenDerslerBind();
        }

        protected void btnSecileniSil_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdSecilenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["secilenTemplateColumn"].FindControl("CheckBox2");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    gaziEntities.OgretmenDersler.Remove(ogretmenDersler);
                }
            }
            gaziEntities.SaveChanges();
            SecilenDerslerBind();            
        }

        protected void btnDersleriOnayla_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdSecilenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["secilenTemplateColumn"].FindControl("CheckBox2");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    ogretmenDersler.OgretmenOnayi = true;
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            SecilenDerslerBind();     
        }

    }
}