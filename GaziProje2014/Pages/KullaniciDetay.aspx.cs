using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class KullaniciDetay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }


        public static SqlConnection CreateFarmaSqlConnection()
        {
            string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
            SqlConnection bag = new SqlConnection(ConStr);
            bag.Open();
            return bag;
        }

        public static DataSet CreateFarmaDataSet(string sql)
        {
            SqlConnection bag = CreateFarmaSqlConnection();
            DataSet ds = new DataSet();
            SqlDataAdapter da = new SqlDataAdapter(sql, bag);
            da.Fill(ds);
            bag.Close();
            return ds;
        }

        public static DataTable CreateFarmaDateTable(string sql)
        {

            SqlConnection bag = CreateFarmaSqlConnection();
            DataTable dt = new DataTable();
            SqlDataAdapter da = new SqlDataAdapter(sql, bag);
            da.Fill(dt);
            bag.Close();
            return dt;
        }

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            
            DataTable dtKullaniciTipleri = CreateFarmaDateTable("Select KullaniciTipId, KullaniciTipAdi from KullaniciTipleri");
            DataTable dtIl = CreateFarmaDateTable("Select IlKodu, IlAdi from Il");
           
            //** Kullanici Tipleri
            cbKullaniciTipleri.DataSource = dtKullaniciTipleri;
            cbKullaniciTipleri.DataTextField = "KullaniciTipAdi";
            cbKullaniciTipleri.DataValueField = "KullaniciTipId";
            cbKullaniciTipleri.DataBind();

            //** Il Kodlari
            cbIlAdi.DataSource = dtIl;
            cbIlAdi.DataTextField = "IlAdi";
            cbIlAdi.DataValueField = "IlKodu";
            cbIlAdi.DataBind();


            if (Request.QueryString["KullaniciId"] == null)
            {
                //DetailsView1.DefaultMode = DetailsViewMode.Insert;
                btnGuncelle.Text = "Ekle";
            }
            else
            {
                //DetailsView1.DefaultMode = DetailsViewMode.Edit;
                btnGuncelle.Text = "Güncelle";
                int KullaniciId = Convert.ToInt32(Request.QueryString["KullaniciId"]);
                string sqlStr = "Select * from Kullanicilar Where KullaniciId = " + KullaniciId.ToString();
        
                DataTable dtKullanicilar = CreateFarmaDateTable(sqlStr);
                DataRow RwKullanicilar = dtKullanicilar.Rows[0];

                cbKullaniciTipleri.SelectedValue = RwKullanicilar["KullaniciTipi"].ToString();
                txtKullaniciAdi.Text = RwKullanicilar["KullaniciAdi"].ToString();
                txtSifre.Text = RwKullanicilar["KullaniciSifre"].ToString();
                txtAdi.Text = RwKullanicilar["Adi"].ToString();
                txtSoyadi.Text = RwKullanicilar["Soyadi"].ToString();
                cbKullaniciTipleri.SelectedValue = RwKullanicilar["Cinsiyet"].ToString();

                //if (RwKullanicilar["DogumTarihi"] != null)
                //    dteDogumTarihi.SelectedDate = Convert.ToDateTime(RwKullanicilar["DogumTarihi"].ToString());

                //if (RwKullanicilar["CepTel"] != null)
                //    txtCepTel.Text = RwKullanicilar["CepTel"].ToString();

                //if (RwKullanicilar["EvTel"] != null)
                //    txtEvTel.Text = RwKullanicilar["EvTel"].ToString();

                //if (!RwKullanicilar.IsEmailNull())
                //    txtemail.Text = RwKullanicilar.Email.ToString();

                cbIlAdi.SelectedValue = RwKullanicilar["IlKodu"].ToString();
                if (cbIlAdi.SelectedValue != null)
                {
                    //** Il Kodlari
                    int IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                    DataTable dtIlce = CreateFarmaDateTable("Select IlceKodu, IlceAdi From Ilce Where IlKodu = " + IlKodu.ToString());

                    cbIlceAdi.DataSource = dtIlce;
                    cbIlceAdi.DataTextField = "IlceAdi";
                    cbIlceAdi.DataValueField = "IlceKodu";
                    cbIlceAdi.DataBind();
                    cbIlceAdi.SelectedValue = RwKullanicilar["IlceKodu"].ToString();
                }
                //txtAdres.Text = RwKullanicilar.Adres.ToString();

                //if (!RwKullanicilar.IsOnayNull())
                //    chkOnay.Checked = RwKullanicilar.Onay;

            }
            this.Page.Title = "Editing record";
        }

        protected void btnGuncelle_Click(object sender, EventArgs e)
        {
            int KullaniciId = Convert.ToInt32(Request.QueryString["KullaniciId"]);
            SqlConnection bag = CreateFarmaSqlConnection();
            DataTable dt = new DataTable();
            SqlDataAdapter da = new SqlDataAdapter("Select * from Kullanicilar Where KullaniciId = " + KullaniciId.ToString(), bag);
            //da.Fill(dt);
            dt.Rows[0].BeginEdit();
            dt.Rows[0]["Soyadi"] = txtSoyadi.Text;
            dt.Rows[0].EndEdit();
            da.Update(dt);
            bag.Close();
            ClientScript.RegisterStartupScript(Page.GetType(), "mykey", "CloseAndRebind();", true);
        }

        protected void cbIlAdi_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            if (cbIlAdi.SelectedValue != null)
            {
                //** Il Kodlari
                cbIlceAdi.SelectedValue = null;
                int IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                DataTable dtIlce = CreateFarmaDateTable("Select IlceKodu, IlceAdi From Ilce Where IlKodu = " + IlKodu.ToString());

                cbIlceAdi.DataSource = dtIlce;
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
                //Sunucuda ki resim klasörünün içerisine seçilen resmi yükledik.
                //Label1.Text = "Dosya Eklendi";
                Image1.ImageUrl = "resim/" + FileUpload1.FileName;
            }
            else
            {
                Response.Write("Dosya Yükleme Hatası");
            }
        }

    }
}