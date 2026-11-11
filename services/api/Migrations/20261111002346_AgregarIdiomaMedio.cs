using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TourVirtualUTB.Api.Migrations
{
    /// <inheritdoc />
    public partial class AgregarIdiomaMedio : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Idioma",
                table: "Medios",
                type: "character varying(35)",
                maxLength: 35,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Idioma",
                table: "Medios");
        }
    }
}
