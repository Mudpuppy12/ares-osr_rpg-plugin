import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';
import DefaultRoute from 'ares-webportal/mixins/default-route';

export default Route.extend(DefaultRoute, {
    gameApi: service(),

    queryParams: {
        tradition: { refreshModel: true }
    },

    model: function(params) {
        let api = this.gameApi;
        let args = {};
        if (params.tradition) {
            args.tradition = params.tradition;
        }
        return api.requestOne('osrRpgSpells', args);
    }
});
