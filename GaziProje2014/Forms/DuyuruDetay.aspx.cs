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
    public partial class DuyuruDetay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                GAZIEntities gaziEntities = new GAZIEntities();
                var kullaniciTipleri = (from kt in gaziEntities.KullaniciTipleri
                                        select new { kt.KullaniciTipId, kt.KullaniciTipAdi }).ToList();

                RadGrid1.DataSource = kullaniciTipleri;
                RadGrid1.DataBind();

                if (Request.QueryString["DuyuruId"] != null)
                {
                    int duyuruId = Convert.ToInt32(Request.QueryString["DuyuruId"]);
                    FillForm(duyuruId);
                }
            }
        }

        private void FillForm(int duyuruId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            Duyurular duyuru = (from d in gaziEntities.Duyurular
                                where d.DuyuruId == duyuruId
                                select d).FirstOrDefault();

            txtDuyuruAdi.Text = duyuru.DuyuruAdi;
            dteDuyuruTarihi.SelectedDate = duyuru.DuyuruTarihi;
            RadEditor1.Content = duyuru.DuyuruIcerik;

            List<DuyuruKullanicilar> duyuruKullanicilar = (from d in gaziEntities.DuyuruKullanicilar
                                                           where d.DuyuruId == duyuruId
                                                           select d).ToList();

            foreach (GridDataItem item in RadGrid1.MasterTableView.Items)
            {
                int KullaniciTipiId = Convert.ToInt32(item["KullaniciTipId"].Text);
                int Check = duyuruKullanicilar.Where(x => x.KullaniciTipiId == KullaniciTipiId).Count();
                if (Check > 0)
                {
                    CheckBox chk = (CheckBox)item["TemplateColumn"].FindControl("CheckBox1");
                    chk.Checked = true;
                }
            }
        }

        protected void btnYayinla_Click(object sender, EventArgs e)
        {
            int KullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();
            Duyurular duyurular = null;
            string mesaj = "";
            if (Request.QueryString["DuyuruId"] != null)
            {
                int duyuruId = Convert.ToInt32(Request.QueryString["DuyuruId"]);
                
                //** Önceki Kayıtkarı Temizle
                var duyuruKullanicilar = (from d in gaziEntities.DuyuruKullanicilar
                                          where d.DuyuruId == duyuruId
                                          select d).ToList();

                foreach (var item in duyuruKullanicilar)
                {
                    gaziEntities.DuyuruKullanicilar.Remove(item);
                }
                gaziEntities.SaveChanges();
                duyurular = gaziEntities.Duyurular.Where(q => q.DuyuruId == duyuruId).FirstOrDefault();
                duyurular.DuyuruAdi = txtDuyuruAdi.Text;
                duyurular.DuyuruIcerik = RadEditor1.Text;
                duyurular.DuyuruTarihi = dteDuyuruTarihi.SelectedDate;
                duyurular.DuyuruKayitEdenId = KullaniciId;
                mesaj = "Duyuru Başarıyla Güncellenmiştir.";
            }
            else
            {
                //** İlk Defa Kaydediliyorsa 
                duyurular = new Duyurular();
                duyurular.DuyuruAdi = txtDuyuruAdi.Text;
                duyurular.DuyuruIcerik = RadEditor1.Content;
                duyurular.DuyuruTarihi = dteDuyuruTarihi.SelectedDate;
                duyurular.DuyuruKayitEdenId = KullaniciId;
                gaziEntities.Duyurular.Add(duyurular);
                mesaj = "Duyuru Başarıyla Eklenmiştir.";
            }
            


            foreach (GridDataItem item in RadGrid1.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["TemplateColumn"].FindControl("CheckBox1");
                if (chk.Checked)
                {
                    int KullaniciTipiId = Convert.ToInt32(item["KullaniciTipId"].Text);
                    DuyuruKullanicilar duyuruKullanicilar = new DuyuruKullanicilar();
                    duyuruKullanicilar.Duyurular = duyurular;
                    duyuruKullanicilar.KullaniciTipiId = KullaniciTipiId;
                    gaziEntities.DuyuruKullanicilar.Add(duyuruKullanicilar);
                }
            }
            gaziEntities.SaveChanges();
            Session["Mesaj"] = mesaj;
            Response.Redirect("DuyuruListe.aspx"); 
        }

        protected void btnTemizle_Click(object sender, EventArgs e)
        {
            txtDuyuruAdi.Text = "";
            dteDuyuruTarihi.SelectedDate = null;
            RadEditor1.Content = "";
            foreach (GridDataItem item in RadGrid1.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["TemplateColumn"].FindControl("CheckBox1");
                chk.Checked = false;
            }
        }

    }
}