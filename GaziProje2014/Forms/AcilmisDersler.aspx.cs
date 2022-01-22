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
    public partial class AcilmisDersler : System.Web.UI.Page
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

        protected void btnDersAlanOgrenci_Click(object sender, EventArgs e)
        {

        }

        protected void btnDersIcerikGor_Click(object sender, EventArgs e)
        {

        }

        private void grdSecilenDerslerBind()
        {
            string sqlText =  "SELECT "
                            + "(SELECT COUNT(*) FROM OgrenciDersler Where OgretmenDersId = OT.OgretmenDersId And UstOnay = 1) as DersAlanOgrenci, "
                            + "OT.OgretmenDersId, OT.OgretmenId, OT.DersId,  "
                            + "K.Adi + ' ' + K.Soyadi as DersiVeren, "
                            + "D.DersAdi, D.DersAciklama "
                            + "FROM OgretmenDersler  OT "
                            + "INNER JOIN Kullanicilar K ON OT.OgretmenId = K.KullaniciId "
                            + "INNER JOIN Dersler D ON D.DersId = OT.DersId "
                            + "WHERE OT.UstOnay = 1 ";


            if (txtDersAdi.Text != "")
                sqlText = sqlText + "And DersAdi like '" + txtDersAdi.Text + "%' ";

            if (txtOgretmenAdi.Text != "")
                sqlText = sqlText + "And K.Adi + ' ' + K.Soyadi like '" + txtOgretmenAdi.Text + "%' ";

            sqlText = sqlText + "ORDER BY DersAlanOgrenci DESC ";

            GAZIDbContext gaziEntities = new GAZIDbContext();
            List<AcilanDers> acilanDersler = gaziEntities.Database.SqlQuery<AcilanDers>(sqlText).ToList();

            grdOgrenciDersSecim.DataSource = acilanDersler;
            grdOgrenciDersSecim.DataBind();
        }

        private class AcilanDers
        {
            public int OgretmenDersId { get; set; }
            public int? OgretmenId { get; set; }
            public int? DersId { get; set; }
            public string DersiVeren { get; set; }
            public string DersAdi { get; set; }
            public string DersAciklama { get; set; }
            public int? DersAlanOgrenci { get; set; }
        }  

    }

    
}