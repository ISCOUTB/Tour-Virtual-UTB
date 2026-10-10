using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.Models;
using TourVirtualUTB.Api.DTOs;

namespace TourVirtualUTB.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EscenasController : ControllerBase
    {
        private readonly TourDbContext _context;
        private readonly IWebHostEnvironment _env;

        // Inyectamos el contexto de BD y el entorno web para saber la ruta de wwwroot
        public EscenasController(TourDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // GET: api/Escenas/lugar/1 -> Flutter lo usará para pedir las fotos de un edificio
        [HttpGet("lugar/{lugarId}")]
        public async Task<ActionResult<IEnumerable<Escena>>> GetEscenasPorLugar(int lugarId)
        {
            return await _context.Escenas.Where(e => e.LugarId == lugarId).ToListAsync();
        }

        // POST: api/Escenas -> Sube la imagen y la guarda
        [HttpPost]
        public async Task<ActionResult<Escena>> PostEscena([FromForm] EscenaCreateDto dto)
        {
            // 1. Validar que enviaron un archivo
            if (dto.ArchivoImagen == null || dto.ArchivoImagen.Length == 0)
                return BadRequest("No se proporcionó ninguna imagen.");

            // 2. Validar que el lugar (ej: Biblioteca) exista
            var lugarExiste = await _context.Lugares.AnyAsync(l => l.Id == dto.LugarId);
            if (!lugarExiste) return NotFound("El Lugar especificado no existe.");

            // 3. Crear el nombre del archivo (usamos Guid para que no se repitan nombres)
            var extension = Path.GetExtension(dto.ArchivoImagen.FileName);
            var nombreArchivo = Guid.NewGuid().ToString() + extension;

            // FIX: Si WebRootPath viene nulo, calculamos la ruta manualmente desde la raíz del proyecto
            var webRootPath = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var rutaCarpeta = Path.Combine(webRootPath, "images");

            // Si la carpeta no existe, la creamos
            if (!Directory.Exists(rutaCarpeta)) Directory.CreateDirectory(rutaCarpeta);

            var rutaCompleta = Path.Combine(rutaCarpeta, nombreArchivo);

            // 4. Guardar el archivo físicamente en tu disco duro
            using (var stream = new FileStream(rutaCompleta, FileMode.Create))
            {
                await dto.ArchivoImagen.CopyToAsync(stream);
            }

            // 5. Construir la URL pública (ej: http://localhost:5xxx/images/mifoto.jpg)
            var urlImagen = $"{Request.Scheme}://{Request.Host}/images/{nombreArchivo}";

            // 6. Guardar el registro en la Base de Datos
            var nuevaEscena = new Escena
            {
                LugarId = dto.LugarId,
                ImagenUrl = urlImagen,
                EsPanoramica = dto.EsPanoramica,
                EsEscenaPrincipal = dto.EsEscenaPrincipal
            };

            _context.Escenas.Add(nuevaEscena);
            await _context.SaveChangesAsync();

            return StatusCode(201, nuevaEscena);
        }
    }
}