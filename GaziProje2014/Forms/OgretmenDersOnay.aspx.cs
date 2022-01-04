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
    public partial class OgretmenDersOnay : System.Web.UI.Page
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

        protected void btnSecilenleriOnayla_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOnayBekleyenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkUstOnay");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    ogretmenDersler.UstOnay = true;
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdOnayBekleyenDerslerBind();
        }

        protected void btnSecilenleriSil_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOnayBekleyenDersler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkUstOnay");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);
                    OgretmenDersler ogretmenDersler = gaziEntities.OgretmenDersler.Where(x => x.OgretmenDersId == ogretmenDersId).FirstOrDefault();
                    gaziEntities.OgretmenDersler.Remove(ogretmenDersler);
                }
            }
            gaziEntities.SaveChanges();
            grdOnayBekleyenDerslerBind();
        }

        private void grdOnayBekleyenDerslerBind()
        {


            GAZIEntities gaziEntities = new GAZIEntities();
            var onayBekleyenDersler = (from od in gaziEntities.OgretmenDersler
                                       join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                       join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                                       where od.OgretmenOnayi == true && (od.UstOnay == null || od.UstOnay == false)
                                       select new { od.OgretmenDersId, d.DersAdi, d.DersAciklama, DersiVeren = k.Adi + " " + k.Soyadi });

            if (txtDersAdi.Text != "")
                onayBekleyenDersler = onayBekleyenDersler.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            if (txtOgretmenAdi.Text != "")
                onayBekleyenDersler = onayBekleyenDersler.Where(q => q.DersiVeren.StartsWith(txtOgretmenAdi.Text));

            grdOnayBekleyenDersler.DataSource = onayBekleyenDersler.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdOnayBekleyenDersler.DataBind();
        }


    }
}