using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TourVirtualUTB.Api.Migrations
{
    /// <inheritdoc />
    public partial class EscenaImagenOpcional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "ImagenUrl",
                table: "Escenas",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            // Los rellenos que se usaban mientras el campo era obligatorio
            // pasan a null, que es lo que significan: "aún sin panorámica".
            migrationBuilder.Sql(
                """UPDATE "Escenas" SET "ImagenUrl" = NULL WHERE btrim("ImagenUrl") IN ('', 'temp', 'string');""");
            migrationBuilder.Sql(
                """UPDATE "Escenas" SET "ImagenUrlBaja" = NULL WHERE btrim("ImagenUrlBaja") IN ('', 'temp', 'string');""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""UPDATE "Escenas" SET "ImagenUrl" = '' WHERE "ImagenUrl" IS NULL;""");

            migrationBuilder.AlterColumn<string>(
                name: "ImagenUrl",
                table: "Escenas",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
