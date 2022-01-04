﻿using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;



namespace GaziProje2014.Kurulum
{
    public partial class Kurulum : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        public static SqlConnection CreateGaziSqlConnection()
        {
            string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
            SqlConnection bag = new SqlConnection(ConStr);
            bag.Open();
            return bag;
        }

        private string ConnectionStringGetir()
        {
            string ConStr = "Data Source=" + txtServerName.Text.Trim() + ";"
                           + "Initial Catalog=" + txtDataBaseName.Text.Trim() + ";"
                           + "Persist Security Info=True;"
                           + "User ID=" + txtDataBaseUser.Text.Trim() + ";"
                           + "Password=" + txtDataBaseSifre.Text.Trim();
            return ConStr;
        }

        private string ConnectionEntitityGetir()
        {
             string ConStr = "metadata=res://*/Data.GaziEgitimModel.csdl|"
                                    + "res://*/Data.GaziEgitimModel.ssdl|"
                                    + "res://*/Data.GaziEgitimModel.msl;"
                                    + "provider=System.Data.SqlClient;"
                                    + "provider connection string=\""
                                    + "data source=" + txtServerName.Text.Trim() + ";"
                                    + "initial catalog=" + txtDataBaseName.Text.Trim() + ";"
                                    + "persist security info=True;"
                                    + "user id=" + txtDataBaseUser.Text.Trim() + ";"
                                    + "password=" + txtDataBaseSifre.Text.Trim() + ";"
                                    + "MultipleActiveResultSets=True;"
                                    + "App=EntityFramework\"";
            return ConStr;
        }

        private bool CheckSqlConnection()
        {
            try
            {
                string ConStr = ConnectionStringGetir();
                SqlConnection bag = new SqlConnection(ConStr);
                bag.Open();
            }
            catch
            {
                return false;
            }
            return true;
        }

        protected void btnDataBase_Click(object sender, EventArgs e)
        {
            var configuration = WebConfigurationManager.OpenWebConfiguration("~");
            var section = (ConnectionStringsSection)configuration.GetSection("connectionStrings");
            ///section.ConnectionStrings["MyConnectionString"].ConnectionString = "Data Source=...";
            section.ConnectionStrings["GAZIConnectionString"].ConnectionString = "Data Source=Test Mest";
            configuration.Save();




            string path = Server.MapPath("~/Kurulum/GAZI.sql");
            FileInfo fileInfo = new FileInfo(path);
            string script = fileInfo.OpenText().ReadToEnd();
            SqlConnection connection = new SqlConnection(ConnectionStringGetir());

            SqlCommand command = new SqlCommand(script, connection);
            SqlDataReader reader = command.ExecuteReader();

            //<add name="GAZIConnectionString" connectionString="Data Source=mssql03.turhost.com;Initial Catalog=uegitim_gazi;Persist Security Info=True;User ID=uegitim_sa;Password=BAKU2005!" providerName="System.Data.SqlClient" />
            //<add name="GAZIEntities" connectionString="metadata=res://*/Data.GaziEgitimModel.csdl|res://*/Data.GaziEgitimModel.ssdl|res://*/Data.GaziEgitimModel.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=mssql03.turhost.com;initial catalog=uegitim_gazi;persist security info=True;user id=uegitim_sa;password=BAKU2005!;MultipleActiveResultSets=True;App=EntityFramework&quot;" providerName="System.Data.EntityClient" />  
        }

        public static void Calistir(string sqlConnectionString)
        {

   
        }

        protected void btnDatabaseTanim_Click(object sender, EventArgs e)
        {
            if (CheckSqlConnection())
            {
                var configuration = WebConfigurationManager.OpenWebConfiguration("~");
                var section = (ConnectionStringsSection)configuration.GetSection("connectionStrings");

                //section.ConnectionStrings["GAZIConnectionString"].ConnectionString = ConnectionStringGetir();
                //section.ConnectionStrings["GAZIEntities"].ConnectionString = ConnectionEntitityGetir();
                //configuration.Save();

                Calistir(ConnectionStringGetir());
                //string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
                //SqlConnection bag = new SqlConnection(ConStr);
                //bag.Open();

                //SqlCommand command = new SqlCommand(queryString, ConStr);
                //SqlDataReader reader = command.ExecuteReader();

            }
            txtDurum.Text = txtDurum.Text + ConnectionStringGetir() + "\n";
            txtDurum.Text = txtDurum.Text + ConnectionEntitityGetir() + "\n";
            CheckSqlConnection();
        }


        //public static SqlConnection CreateFarmaSqlConnection()
        //{
        //    string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
        //    SqlConnection bag = new SqlConnection(ConStr);
        //    bag.Open();
        //    return bag;
        //}

    }
}