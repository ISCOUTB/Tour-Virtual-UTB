using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HotspotsController : ControllerBase
    {
        private readonly TourDbContext _context;

        public HotspotsController(TourDbContext context)
        {
            _context = context;
        }

        // GET: api/Hotspots/escena/1
        // Flutter consumirá esto para saber dónde dibujar los botones interactivos en la foto 360 actual
        [HttpGet("escena/{escenaId}")]
        public async Task<ActionResult<IEnumerable<Hotspot>>> GetHotspotsPorEscena(int escenaId)
        {
            return await _context.Hotspots
                .Where(h => h.EscenaOrigenId == escenaId)
                .ToListAsync();
        }

        // POST: api/Hotspots
        // El administrador lo usará para conectar dos escenas (ej: Entrada -> Pasillo)
        [HttpPost]
        public async Task<ActionResult<Hotspot>> PostHotspot(Hotspot hotspot)
        {
            // Verificamos que ambas escenas existan antes de conectarlas
            var escenaOrigenExiste = await _context.Escenas.AnyAsync(e => e.Id == hotspot.EscenaOrigenId);
            var escenaDestinoExiste = await _context.Escenas.AnyAsync(e => e.Id == hotspot.EscenaDestinoId);

            if (!escenaOrigenExiste || !escenaDestinoExiste)
            {
                return BadRequest("La escena de origen o destino no existe.");
            }

            _context.Hotspots.Add(hotspot);
            await _context.SaveChangesAsync();

            return StatusCode(201, hotspot);
        }
    }
}