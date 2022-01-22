using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class KullaniciDetay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        //public static SqlConnection CreateFarmaSqlConnection()
        //{
        //    string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
        //    SqlConnection bag = new SqlConnection(ConStr);
        //    bag.Open();
        //    return bag;
        //}

        //public static DataSet CreateFarmaDataSet(string sql)
        //{
        //    SqlConnection bag = CreateFarmaSqlConnection();
        //    DataSet ds = new DataSet();
        //    SqlDataAdapter da = new SqlDataAdapter(sql, bag);
        //    da.Fill(ds);
        //    bag.Close();
        //    return ds;
        //}

        //public static DataTable CreateFarmaDateTable(string sql)
        //{

        //    SqlConnection bag = CreateFarmaSqlConnection();
        //    DataTable dt = new DataTable();
        //    SqlDataAdapter da = new SqlDataAdapter(sql, bag);
        //    da.Fill(dt);
        //    bag.Close();
        //    return dt;
        //}

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            GAZIDbContext gaziEntities = new GAZIDbContext();

            //** Kullanici Tipleri
            var kullaniciTipleri = gaziEntities.KullaniciTipleri.ToList();
            cbKullaniciTipleri.DataSource = kullaniciTipleri;
            cbKullaniciTipleri.DataValueField = "KullaniciTipId";
            cbKullaniciTipleri.DataTextField = "KullaniciTipAdi";
            cbKullaniciTipleri.DataBind();

            //** Il 
            var il = gaziEntities.Il.OrderBy(q => q.IlKodu).ToList();
            cbIlAdi.DataSource = il;
            cbIlAdi.DataValueField = "IlKodu";
            cbIlAdi.DataTextField = "IlAdi";
            cbIlAdi.DataBind();            

            if (Request.QueryString["KullaniciId"] != null)
            {
                int kullaniciId = Convert.ToInt32(Request.QueryString["KullaniciId"]);

                Kullanicilar kullanicilar = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
                if (kullanicilar != null)
                {
                    txtKullaniciAdi.Text = kullanicilar.KullaniciAdi;
                    txtSifre.Text = kullanicilar.KullaniciSifre;
                    txtAdi.Text = kullanicilar.Adi;
                    txtSoyadi.Text = kullanicilar.Soyadi;
                    cbKullaniciTipleri.SelectedValue = kullanicilar.KullaniciTipi.ToString();
                    cbCinsiyet.SelectedValue = kullanicilar.Cinsiyet.ToString();

                    if (kullanicilar.DogumTarihi != null)
                        dteDogumTarihi.SelectedDate = kullanicilar.DogumTarihi;

                    txtCepTel.Text = kullanicilar.CepTel;
                    txtEvTel.Text = kullanicilar.EvTel;
                    txtemail.Text = kullanicilar.Email;
                    txtAdres.Text = kullanicilar.Adres;
                    chkOnay.Checked = kullanicilar.Onay.Value;

                    if (kullanicilar.Resim != "")
                    {
                        hdnResimUrl.Value = kullanicilar.Resim;
                        ImgProfilResim.ImageUrl = kullanicilar.Resim;
                    }

                    //**Ilce
                    if (kullanicilar.IlKodu != null)
                    {
                        cbIlAdi.SelectedValue = kullanicilar.IlKodu.ToString();
                        var ilce = gaziEntities.Ilce.Where(q => q.IlKodu == kullanicilar.IlKodu).ToList();
                        cbIlceAdi.DataSource = ilce;
                        cbIlceAdi.DataValueField = "IlceKodu";
                        cbIlceAdi.DataTextField = "IlceAdi";
                        cbIlceAdi.DataBind();
                        if (kullanicilar.IlceKodu != null)
                            cbIlceAdi.SelectedValue = kullanicilar.IlceKodu.ToString();
                    }
                    this.Page.Title = kullanicilar.KullaniciAdi + " kullanıcısının detayları";
                }
            }
            else
            {
                btnGuncelle.Text = "Ekle";
                this.Page.Title = "Yeni Kullanıcı Ekle";
            }
        }

        protected void btnGuncelle_Click(object sender, EventArgs e)
        {
            int KullaniciId = Convert.ToInt32(Request.QueryString["KullaniciId"]);

            GAZIDbContext gaziEntities = new GAZIDbContext();

            if (KullaniciId > 0)
            {
                Kullanicilar Kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == KullaniciId).FirstOrDefault();
                Kullanici.KullaniciTipi = Convert.ToInt32(cbKullaniciTipleri.SelectedValue);
                Kullanici.KullaniciAdi = txtKullaniciAdi.Text;
                Kullanici.KullaniciSifre = txtSifre.Text;
                Kullanici.Adi = txtAdi.Text;
                Kullanici.Soyadi = txtSoyadi.Text;
                Kullanici.Cinsiyet = Convert.ToInt32(cbCinsiyet.SelectedValue);
                Kullanici.DogumTarihi = dteDogumTarihi.SelectedDate;
                Kullanici.CepTel = txtCepTel.Text;
                Kullanici.EvTel = txtEvTel.Text;
                Kullanici.Email = txtemail.Text;
                Kullanici.Adres = txtAdres.Text;
                Kullanici.IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                Kullanici.IlceKodu = Convert.ToInt32(cbIlceAdi.SelectedValue);              
                Kullanici.Onay = chkOnay.Checked;
                Kullanici.Resim = hdnResimUrl.Value;
                gaziEntities.SaveChanges();
  
            }
            else
            {
                Kullanicilar Kullanici = new Kullanicilar();
                Kullanici.KullaniciTipi = Convert.ToInt32(cbKullaniciTipleri.SelectedValue);
                Kullanici.KullaniciAdi = txtKullaniciAdi.Text;
                Kullanici.KullaniciSifre = txtSifre.Text;
                Kullanici.Adi = txtAdi.Text;
                Kullanici.Soyadi = txtSoyadi.Text;
                Kullanici.Cinsiyet = Convert.ToInt32(cbCinsiyet.SelectedValue);
                Kullanici.DogumTarihi = dteDogumTarihi.SelectedDate;
                Kullanici.CepTel = txtCepTel.Text;
                Kullanici.EvTel = txtEvTel.Text;
                Kullanici.Email = txtemail.Text;
                Kullanici.Adres = txtAdres.Text;
                Kullanici.IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                Kullanici.IlceKodu = Convert.ToInt32(cbIlceAdi.SelectedValue);
                Kullanici.Onay = chkOnay.Checked;
                Kullanici.Resim = hdnResimUrl.Value;
                gaziEntities.Kullanicilar.Add(Kullanici);
                gaziEntities.SaveChanges();
            }
            ClientScript.RegisterStartupScript(Page.GetType(), "mykey", "CloseAndRebind();", true);
        }
        
        protected void cbIlAdi_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            if (cbIlAdi.SelectedValue != null)
            {
                //** Il Kodlari
                cbIlceAdi.SelectedValue = null;
                int IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);

                GAZIDbContext gaziEntities = new GAZIDbContext();
                List<Ilce> ilce = gaziEntities.Ilce.Where(q => q.IlKodu == IlKodu).ToList();

                //** Il Kodlari
                cbIlceAdi.DataSource = ilce;
                cbIlceAdi.DataTextField = "IlceAdi";
                cbIlceAdi.DataValueField = "IlceKodu";
                cbIlceAdi.DataBind();
            }
        }

        protected void btnYukle_Click(object sender, EventArgs e)
        {
            if (FileUpload1.HasFile) //Kullanıcı browse tuşuna basarak dosya seçtiyse aşağıdaki kodlar çalışacak.
            {
                FileUpload1.SaveAs(Server.MapPath("Resim/") + FileUpload1.FileName);
                ImgProfilResim.ImageUrl = "Resim/" + FileUpload1.FileName;
                hdnResimUrl.Value = "Resim/" + FileUpload1.FileName; 
            }
            else
            {
                Response.Write("Dosya Yükleme Hatası");
            }
        }

    }
}