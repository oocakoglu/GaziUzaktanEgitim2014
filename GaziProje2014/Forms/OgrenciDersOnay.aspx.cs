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
    public partial class OgrenciDersOnay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdOgrenciDersOnayBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdOgrenciDersOnayBind();
        }

        protected void btnSecilenleriOnayla_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOgrenciDersOnay.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkUstOnay");
                if (chk.Checked)
                {
                    int ogrenciDersId = Convert.ToInt32(item["OgrenciDersId"].Text);
                    OgrenciDersler ogrenciDersler = gaziEntities.OgrenciDersler.Where(x => x.OgrenciDersId == ogrenciDersId).FirstOrDefault();
                    ogrenciDersler.UstOnay = true;   
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdOgrenciDersOnayBind();
        }

        protected void btnSecilenleriSil_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOgrenciDersOnay.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkUstOnay");
                if (chk.Checked)
                {
                    int ogrenciDersId = Convert.ToInt32(item["OgrenciDersId"].Text);
                    OgrenciDersler ogrenciDersler = gaziEntities.OgrenciDersler.Where(x => x.OgrenciDersId == ogrenciDersId).FirstOrDefault();
                    gaziEntities.OgrenciDersler.Remove(ogrenciDersler);
                }
            }
            gaziEntities.SaveChanges();
            grdOgrenciDersOnayBind();
        }

        private void grdOgrenciDersOnayBind()
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            var ogrenciDersOnay = (from ogrncD in gaziEntities.OgrenciDersler
                                   join ogrtmnD in gaziEntities.OgretmenDersler on ogrncD.OgretmenDersId equals ogrtmnD.OgretmenDersId
                                   join d in gaziEntities.Dersler on ogrtmnD.DersId equals d.DersId
                                   join kogrtmn in gaziEntities.Kullanicilar on ogrtmnD.OgretmenId equals kogrtmn.KullaniciId
                                   join kogrnc in gaziEntities.Kullanicilar on ogrncD.OgrenciId equals kogrnc.KullaniciId
                                   where ogrncD.OgrenciOnayi == true && (ogrncD.UstOnay == null || ogrncD.UstOnay == false)
                                   select new {
                                                ogrncD.OgrenciDersId, 
                                                ogrtmnD.OgretmenDersId,                                                 
                                                ogrncD.OgrenciId,
                                                ogrtmnD.OgretmenId,
                                                d.DersAdi, 
                                                d.DersAciklama,                                                
                                                DersiVeren = kogrtmn.Adi + " " + kogrtmn.Soyadi,
                                                DersiAlan = kogrnc.Adi + " " + kogrnc.Soyadi
                                               });


            if (txtDersAdi.Text != "")
                ogrenciDersOnay = ogrenciDersOnay.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            if (txtOgretmenAdi.Text != "")
                ogrenciDersOnay = ogrenciDersOnay.Where(q => q.DersiVeren.StartsWith(txtOgretmenAdi.Text));

            if (txtOgrenciAdi.Text != "")
                ogrenciDersOnay = ogrenciDersOnay.Where(q => q.DersiAlan.StartsWith(txtOgrenciAdi.Text));

            grdOgrenciDersOnay.DataSource = ogrenciDersOnay.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdOgrenciDersOnay.DataBind();
        }

        

    }
}