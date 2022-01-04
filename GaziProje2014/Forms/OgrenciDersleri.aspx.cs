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
    public partial class OgrenciDersleri : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdSecilenDerslerBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdSecilenDerslerBind();
        }

        protected void btnDersleriOnayla_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOgrenciDersSecim.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgrenciOnay");
                if (chk.Checked)
                {
                    int ogrenciDersId = Convert.ToInt32(item["OgrenciDersId"].Text);

                    OgrenciDersler ogrenciDersler = gaziEntities.OgrenciDersler.Where(q => q.OgrenciDersId == ogrenciDersId).FirstOrDefault();
                    ogrenciDersler.OgrenciOnayi = true;
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdSecilenDerslerBind();
        }

        protected void btnDersleriSil_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            foreach (GridDataItem item in grdOgrenciDersSecim.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgrenciOnay");
                if (chk.Checked)
                {
                    int ogrenciDersId = Convert.ToInt32(item["OgrenciDersId"].Text);
                    OgrenciDersler ogrenciDersler = gaziEntities.OgrenciDersler.Where(q => q.OgrenciDersId == ogrenciDersId).FirstOrDefault();
                    gaziEntities.OgrenciDersler.Remove(ogrenciDersler);
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdSecilenDerslerBind();
        }

        protected void btnDersIcerik_Click(object sender, EventArgs e)
        {
            if (grdOgrenciDersSecim.SelectedItems.Count > 0)
            {
                string ogretmenDersId = grdOgrenciDersSecim.SelectedValues["OgretmenDersId"].ToString();
                bool? yoneticiOnay = (bool?)grdOgrenciDersSecim.SelectedValues["UstOnay"];

                if (yoneticiOnay == true)
                {
                    Session.Add("OgretmenDersId", ogretmenDersId);
                    Response.Redirect("~/Forms/OgrenciDersKonular.aspx");
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
            GAZIEntities gaziEntities = new GAZIEntities();
                        
            var dersSecimListesi = (from ogrc in gaziEntities.OgrenciDersler
                                    join od in gaziEntities.OgretmenDersler on ogrc.OgretmenDersId equals od.OgretmenDersId
                                    join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                    join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                                    where ogrc.OgrenciId == kullaniciId
                                    select new { ogrc.OgrenciDersId, ogrc.OgretmenDersId, ogrc.OgrenciOnayi, ogrc.UstOnay, d.DersAdi, d.DersAciklama, DersiVeren = k.Adi + " " + k.Soyadi });

            if (txtDersAdi.Text != "")
                dersSecimListesi = dersSecimListesi.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            if (txtOgretmenAdi.Text != "")
                dersSecimListesi = dersSecimListesi.Where(q => q.DersiVeren.StartsWith(txtOgretmenAdi.Text));


            grdOgrenciDersSecim.DataSource = dersSecimListesi.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdOgrenciDersSecim.DataBind();
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }

    }
}