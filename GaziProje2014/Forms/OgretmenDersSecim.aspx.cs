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
    public partial class OgretmenDersSecim : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdOnayBekleyenDerslerBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdOnayBekleyenDerslerBind();
        }

        protected void btnOgretmenDersSec_Click(object sender, EventArgs e)
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOgretmenDersSecim.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgretmenOnay");
                if (chk.Checked)
                {
                    int dersId = Convert.ToInt32(item["DersId"].Text);
                    int KayitSayi = gaziEntities.OgretmenDersler.Where(x => x.OgretmenId == kullaniciId && x.DersId == dersId).Count();
                    if (KayitSayi == 0)
                    {
                        OgretmenDersler kullaniciDersler = new OgretmenDersler();
                        kullaniciDersler.DersId = dersId;
                        kullaniciDersler.OgretmenId = kullaniciId;
                        kullaniciDersler.OgretmenOnayi = true;
                        gaziEntities.OgretmenDersler.Add(kullaniciDersler);
                    }
                }
            }
            gaziEntities.SaveChanges();
            grdOnayBekleyenDerslerBind();
        }

        private void grdOnayBekleyenDerslerBind()
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();

            //** Ogrencinin daha önce seçtiği dersler
            var ogretmenDersIds = from ogtd in gaziEntities.OgretmenDersler
                                  where ogtd.OgretmenId == kullaniciId
                                  select ogtd.DersId;

            var dersler = (from d in gaziEntities.Dersler
                           where !ogretmenDersIds.Contains(d.DersId)
                           select d).Where(q => q.DersDurum == true);

            if (txtDersAdi.Text != "")
                dersler = dersler.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            grdOgretmenDersSecim.DataSource = dersler.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdOgretmenDersSecim.DataBind();
        }
    }
}