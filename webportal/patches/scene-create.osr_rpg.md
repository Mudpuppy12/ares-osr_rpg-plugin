# scene-create.hbs — OSR Equipment Shop link

Core portal file: `ares-webportal/app/templates/scene-create.hbs`

Add an info banner after the `<h1>Create a Scene</h1>` heading so approved players can visit the post-chargen shop before starting a scene:

```hbs
<div class="alert alert-info">
  Need gear before your adventure?
  <LinkTo @route="osr-rpg-shop" class="btn btn-sm btn-secondary">Equipment Shop</LinkTo>
</div>
```

Optional: in `ares-webportal/app/templates/play.hbs`, add a shop shortcut next to Create Scene for approved users:

```hbs
<TooltipButton @position="right" @message="Equipment Shop" @icon="fa fa-shopping-cart" @route="osr-rpg-shop" />
```

Register the route in `ares-webportal/app/custom-routes.js`:

```javascript
router.route('osr-rpg-shop', { path: '/osr_rpg/shop' });
```

Add a Play menu entry in `game/config/website.yml` after **Start New Scene**:

```yaml
- title: Equipment Shop
  route: osr-rpg-shop
```
