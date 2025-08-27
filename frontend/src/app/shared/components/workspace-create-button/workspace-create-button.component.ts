//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { combineLatest } from 'rxjs';
import { take } from 'rxjs/operators';

@Component({
  selector: 'button[workspace-create-button]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './workspace-create-button.component.html',
  host: {
    '[disabled]': 'disabled',
    '[attr.aria-label]': 'text.explanation',
    '[title]': 'text.title',
    'opWorkspaceCreateDropdown': '',
    '[dropdownActive]': 'canCreateAnyWorkspace'
  },
  standalone: false,
})
export class WorkspaceCreateButtonComponent extends UntilDestroyedMixin implements OnInit {
  disabled = false;

  canCreateAnyWorkspace = false;

  text = {
    title: this.I18n.t('js.label_workspace'),
    createWithDropdown: this.I18n.t('js.workspaces.create.button'),
    explanation: this.I18n.t('js.workspaces.create.button'),
  };

  constructor(
    readonly currentUser:CurrentUserService,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit() {
    // Check if user can create any type of workspace (project, program, or portfolio)
    combineLatest([
      this.currentUser.hasCapabilities$('projects/create', 'global'),
      this.currentUser.hasCapabilities$('programs/create', 'global'),
      this.currentUser.hasCapabilities$('portfolios/create', 'global'),
    ])
      .pipe(take(1))
      .subscribe(([canCreateProject, canCreateProgram, canCreatePortfolio]) => {
        this.canCreateAnyWorkspace = canCreateProject || canCreateProgram || canCreatePortfolio;
        this.disabled = !this.canCreateAnyWorkspace;
        this.cdRef.detectChanges();
      });
  }
}
